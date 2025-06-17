---
title: 通过文生图模型在 Scratch 3 背景区生成图片
date: 2024-08-15
updated: 2024-08-15
categories: 创界编途·Scratch新章
keywords: 创界编途·Scratch新章
top_img: /img/scratch_custom/scratch-bg.png
cover: /img/scratch_custom/scratch-cover.jpg
---

经过在角色区和造型区成功生成图片的历程之后，最后的任务就是在背景区通过文生图模型生成图片了。这次任务相对来说也是最简单的一步，因为它和之前的逻辑非常相似，只是在 Scratch 3 的背景区操作图片。

## 遇到的问题

在实现背景区生成图片时，我已经有了之前的角色和造型区开发的经验，因此这次遇到的挑战并不多。主要需要注意的是，背景的处理和造型类似，但需要确保它被设置为舞台的当前背景。

## 解决方法

这里同样使用了 `TextGeneratedPic` 方法来处理图片的生成。我们通过文生图模型获取到的图片 URL，然后调用 `addBackdropToStage` 方法将该图片设置为背景。

### 关键代码

```javascript
async TextGeneratedPic(args, util) {
    const imageUrl = this.imageUrl
    const stage = this.runtime.getTargetForStage()
    await this.addBackdropToStage(stage, imageUrl, util)
}
```

这段代码的作用是获取舞台对象 stage，并将图片 URL 传递给 addBackdropToStage 方法，以完成背景的设置。

## 背景的处理与添加

```javascript
async addBackdropToStage(stage, imageUrl, util) {
    try {
      const response = await fetch(imageUrl)
      const blob = await response.blob()
      const imageBitmap = await createImageBitmap(blob)
      const extractedContent = this.imageUrl.split('.png')[0]

      const md5 = extractedContent

      const canvas = document.createElement('canvas')
      canvas.width = imageBitmap.width
      canvas.height = imageBitmap.height
      const context = canvas.getContext('2d')
      context.drawImage(imageBitmap, 0, 0)

      const pngDataUrl = canvas.toDataURL('image/png')
      const base64Data = pngDataUrl.split(',')[1]

      const binaryString = atob(base64Data)
      const binaryLen = binaryString.length
      const bytes = new Uint8Array(binaryLen)
      for (let i = 0; i < binaryLen; i++) {
        const ascii = binaryString.charCodeAt(i)
        bytes[i] = ascii
      }

      const backdrop = {
        asset: null,
        md5: `${md5}.png`,
        name: this.fileName + new Date().getTime(),
        bitmapResolution: 2,
        rotationCenterX: imageBitmap.width / 2,
        rotationCenterY: imageBitmap.height / 2,
        skinId: null,
        dataFormat: 'png'
      }

      const storage = stage.runtime.storage
      const asset = storage.createAsset(
        AssetType.ImageBitmap,
        'png',
        bytes,
        md5
      )

      backdrop.asset = asset
      backdrop.assetId = asset.assetId

      const skinId = await stage.runtime.renderer.createBitmapSkin(imageBitmap, backdrop.bitmapResolution)
      backdrop.skinId = skinId

      console.log(stage.sprite, 'stage.sprite')

      stage.sprite.costumes.push(backdrop)
      stage.setCostume(stage.sprite.costumes.length - 1)
      this.runtime.emit("SAY", util.target, "say", '')
      console.log('背景已成功添加并设置为当前背景')
    } catch (error) {
      console.error('添加背景时出错:', error)
    }
}
```

## 代码解析
图片的加载与处理：与之前处理角色和造型时类似，我们通过 fetch 从 imageUrl 获取图片，并将其转换为 imageBitmap。通过 canvas 将图片绘制为 Base64，接着将 Base64 数据解析为二进制数据，构建背景的 backdrop 对象。

背景对象的创建：backdrop 对象包含了图片的 MD5 值、名称、分辨率等信息，并通过 Scratch 的存储机制创建了对应的图片资源 asset。

背景的设置：最终将背景对象添加到舞台的 costumes 列表中，并设置为当前背景。为了确保背景正确渲染，还调用了 setCostume 方法。

## 经验与收获
与之前在角色区和造型区生成图片相比，在背景区生成图片是整个任务的最后一步，也是最简单的一步。通过前面的开发经历，我对 Scratch 的渲染机制有了更深入的理解。在背景的设置过程中，主要工作依然是处理图片的格式，并确保它能够正确显示在舞台上。

这次开发也标志着我在通过文生图模型生成图片任务上的全部完成。从角色区、造型区到背景区，我成功实现了在 Scratch 3 中通过文生图生成的图片动态添加的功能。

![生成中](/img/scratch_custom/img-5.png)

![已完成](/img/scratch_custom/img-6.png)