---
title: 解决苹果手机<audio>标签播放错误
date: 2024-08-21
updated: 2024-08-21
categories: 编海拾遗录
keywords: 编海拾遗录
top_img: /img/fix_tales/fix-tales-bg.png
cover: /img/fix_tales/fix-tales-cover.png
---

在开发过程中，我遇到了一个棘手的问题。在一个项目中，我需要在网页上播放音频文件，使用了标准的`audio`标签。在大部分设备上，这个功能都能正常工作，但当我在苹果手机（iOS设备）上测试时，却发现音频根本无法播放。

## 挫折与困惑

当时，我尝试了很多方法来解决这个问题，甚至开始怀疑是不是音频文件格式不对，或者是代码的其他部分出了问题。我检查了音频的格式，确保它是MP3，而且代码在其他平台上运行良好，这一切都让我感到更加困惑。

我开始怀疑是不是因为苹果设备对音频处理的方式有所不同，于是我查阅了大量的资料，试图找到问题的根源。

## 寻找解决方法

在经过搜索和实验后，我偶然发现了一个关于ID3标签的讨论。有开发者提到，苹果手机可能无法正确解析含有ID3标签的音频文件，看到这条信息时，我的直觉告诉我这可能就是问题的关键所在。

接下来，我便开始寻找解决方案。幸运的是，我找到了一个名为`browser-id3-writer`的JavaScript库，它可以帮助我操作和移除音频文件中的ID3标签。

## 实施解决方案

于是，我决定尝试一下这个库。首先，我通过npm安装了`browser-id3-writer`：

```bash
npm install browser-id3-writer --save
```

安装完成后，我编写了一个方法，使用这个库来移除音频文件中的ID3标签。代码如下：


```javascript
import { ID3Writer } from 'browser-id3-writer'

async function removeID3Tags(audioUrl) {
  try {
    // 获取音频文件的ArrayBuffer
    const response = await fetch(audioUrl)
    const arrayBuffer = await response.arrayBuffer()
    
    // 创建ID3Writer实例并移除ID3标签
    const writer = new ID3Writer(new Uint8Array(arrayBuffer))
    writer.removeTag() // 移除 ID3 标签
    const cleanedArrayBuffer = writer.arrayBuffer
    
    // 将处理后的音频文件转为 Blob
    const cleanedAudioBlob = new Blob([cleanedArrayBuffer], { type: 'audio/mp3' })
    
    // 上传处理后的音频文件并获取新的URL
    const res = await uploadOss.UploadMusic(cleanedAudioBlob)
    console.log(res, 'res')
    
    // 返回处理后的音频URL
    return res
  } catch (error) {
    console.error('Failed to remove ID3 tags:', error)
    // 发生错误时返回原始的音频URL
    return audioUrl
  }
}
```

在这个方法中，我首先通过fetch获取音频文件的数据，并使用ID3Writer移除ID3标签。然后，我将处理后的音频数据上传到服务器，最后获取一个新的URL，用于在网页中播放音频。

这一次终于找到了问题的症结，苹果手机上音频终于能够正常播放了。

## 反思与总结

通过这次经历，我不仅解决了一个技术问题，也学到了很多新的知识，特别是在音频处理和跨平台兼容性方面。希望我的经验能帮助到遇到类似问题的开发者，也希望大家在开发的路上少一些挫折，多一些收获。