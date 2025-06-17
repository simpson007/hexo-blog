---
title: 通过文生图模型在 Scratch 3 造型区生成图片
date: 2024-08-12
updated: 2024-08-12
categories: 创界编途·Scratch新章
keywords: 创界编途·Scratch新章
top_img: /img/scratch_custom/scratch-bg.png
cover: /img/scratch_custom/scratch-cover.jpg
---

在解决了通过文生图模型在角色区生成图片的问题之后，我接下来挑战的目标是通过同样的方式，在 Scratch 3 的造型区添加图片。由于之前已经在角色区生成图片取得了成功，这一次的任务相对容易些，但仍然有一些值得分享的细节和经验。

## 遇到的问题

这个任务的难度较低，主要原因是造型的添加逻辑和角色的添加非常类似。我只需要将新生成的图片作为一个造型附加到已有的角色上，而不必像之前那样去处理复杂的角色渲染和层次管理。

然而，造型的添加过程中，仍然需要注意图片的格式处理，以及如何将生成的图片成功转换为 Scratch 内部识别的 `costume` 对象，并设置为当前的造型。

## 解决方法

我沿用了之前添加角色时的一部分代码，并根据造型的特点对其进行了调整。以下是关键的代码：

```javascript
async TextGeneratedPic(args, util) {
    const imageUrl = this.imageUrl
    const target = util.target
    await this.addCostumeToTarget(target, imageUrl, util)
}
```

在这段代码中，TextGeneratedPic 方法会接收生成的图片 URL，并调用 addCostumeToTarget 方法将其添加到目标角色的造型列表中。

## 造型的添加与设置

以下是 addCostumeToTarget 方法的详细代码：

```javascript
async addCostumeToTarget(target, imageUrl, util) {
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

        const costume = {
            asset: null,
            md5: `${md5}.png`,
            name: this.fileName + new Date().getTime(),
            bitmapResolution: 2,
            rotationCenterX: imageBitmap.width / 2,
            rotationCenterY: imageBitmap.height / 2,
            skinId: null,
            dataFormat: 'png'
        }

        // 存储图片资源并创建皮肤
        const storage = target.runtime.storage
        const asset = storage.createAsset(
            AssetType.ImageBitmap,
            'png',
            bytes,
            md5
        )

        costume.asset = asset
        costume.assetId = asset.assetId

        const skinId = await target.runtime.renderer.createBitmapSkin(imageBitmap, costume.bitmapResolution)
        costume.skinId = skinId

        // 添加造型并设置为当前造型
        target.sprite.costumes.push(costume)
        target.setCostume(target.sprite.costumes.length - 1)
        this.runtime.emit("SAY", util.target, "say", '')
        console.log('造型已成功添加并设置为当前造型')
    } catch (error) {
        console.error('添加造型时出错:', error)
    }
}
```

## 关键步骤解析

图片的加载与转换：首先，使用 fetch 方法从 imageUrl 中获取图片，并通过 createImageBitmap 将图片转换为 imageBitmap 对象。然后，通过 canvas 将图片绘制并转化为 Base64 数据。

创建造型对象：接下来，将图片数据转换为 costume 对象。costume 包含了图片的 MD5、名称、分辨率等信息，这与角色区的图片处理逻辑类似。

添加与设置当前造型：将新的造型添加到目标角色的 costumes 列表中，并通过 setCostume 方法将其设置为当前造型。

## 收获与总结

相比之前在角色区生成图片的任务，这次在造型区生成图片要容易许多，主要的工作还是在图片的处理和造型的添加上。经过之前的经验积累，我在这次任务中遇到的问题较少，代码的整体思路也相对清晰。

![生成中](/img/scratch_custom/img-3.png)

![已完成](/img/scratch_custom/img-4.png)