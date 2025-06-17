---
title: 通过文生图模型在 Scratch 3 角色区生成图片
date: 2024-08-11
updated: 2024-08-11
categories: 创界编途·Scratch新章
keywords: 创界编途·Scratch新章
top_img: /img/scratch_custom/scratch-bg.png
cover: /img/scratch_custom/scratch-cover.jpg
---

在进行 Scratch 3 的二次开发过程中，我遇到了一个特别棘手的问题：如何通过文生图模型生成的图片，在 Scratch 的角色区成功添加一个新的角色。看似简单的任务背后，却隐藏着不少意想不到的困难。以下是我解决这个问题的完整经历。

## 遇到的问题

起初，我的目标很明确——通过文本生成图片，并将该图片添加为一个新的角色到 Scratch 的角色区。然而，实际操作过程中，我遭遇了多个问题：

1. **图片的处理**：将通过文生图模型生成的图片 URL 转换为 Scratch 可以识别和使用的角色数据，过程中涉及到图片的加载、数据格式的转换，以及图片与 Scratch 内部数据结构的对接，这一步的复杂程度超出了我的预期。

2. **角色的创建与渲染**：在 Scratch 中，添加新角色不仅仅是将图片插入这么简单，它需要严格遵守 Scratch 的角色生成与渲染机制。我在这一步中多次遇到渲染失败的情况，角色始终无法正确显示在舞台上。

3. **层次管理**：Scratch 的角色具有层次关系，如何在不影响其他角色的前提下正确设置新角色的层次顺序，也是一个必须解决的问题。

## 解决方法

经过多次调试与查阅文档，我逐渐理清了问题的脉络，并最终找到了有效的解决方法。以下是关键的代码片段及其背后的思路：

```javascript
async TextGeneratedPic(args, util) {
    const imageUrl = this.imageUrl // 通过文生图模型获取的图片url
    await this.addNewSprite(imageUrl, util)
}
```

图片处理与角色创建

首先，我编写了 addNewSprite 方法，负责将生成的图片转换为 Scratch 可以识别的格式，并创建新角色。

```javascript
async addNewSprite(imageUrl, util) {
    try {
        const response = await fetch(imageUrl)
        const blob = await response.blob()
        const imageBitmap = await createImageBitmap(blob)
        const extractedContent = imageUrl.split('.png')[0]
        const md5 = extractedContent

        // 创建 canvas，将图片绘制到 canvas 上
        const canvas = document.createElement('canvas')
        canvas.width = imageBitmap.width
        canvas.height = imageBitmap.height
        const context = canvas.getContext('2d')
        context.drawImage(imageBitmap, 0, 0)

        // 将 canvas 转换为 Base64 格式
        const pngDataUrl = canvas.toDataURL('image/png')
        const base64Data = pngDataUrl.split(',')[1]

        // 将 Base64 数据转换为二进制数据
        const binaryString = atob(base64Data)
        const binaryLen = binaryString.length
        const bytes = new Uint8Array(binaryLen)
        for (let i = 0; i < binaryLen; i++) {
            const ascii = binaryString.charCodeAt(i)
            bytes[i] = ascii
        }

        // 创建角色的 costume 对象
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

        // 处理图片资源
        const storage = this.runtime.storage
        const asset = storage.createAsset(
            AssetType.ImageBitmap,
            'png',
            bytes,
            md5
        )
        costume.asset = asset
        costume.assetId = asset.assetId

        // 渲染新角色
        const skinId = await this.runtime.renderer.createBitmapSkin(imageBitmap, costume.bitmapResolution)
        costume.skinId = skinId

        const spriteName = this.dddabc
        const sprite = new Sprite(null, this.runtime)
        sprite.costumes = [costume]
        sprite.name = spriteName + new Date().getTime()
        sprite.sounds = []
        sprite.variables = {}
        sprite.lists = {}
        sprite.broadcasts = {}
        sprite.comments = {}
        sprite.clones = []
        sprite.layerOrder = 0

        const blocks = new Blocks(this.runtime, sprite)
        blocks.forceNoGlow = false
        sprite.blocks = blocks

        const target = new RenderedTarget(sprite, this.runtime)
        target.id = uid()
        target.blocks = blocks
        target.runtime = this.runtime

        sprite.clones.push(target)

        const group = 'sprite'
        if (this.runtime.renderer._layerGroups && this.runtime.renderer._layerGroups[group]) {
            const drawableID = this.runtime.renderer.createDrawable(group)
            if (drawableID === undefined) {
                console.error('Failed to create drawable')
                return
            }

            target.drawableID = drawableID
            this.runtime.renderer.updateDrawableSkinId(drawableID, skinId)
            target.setVisible(true)

            let maxLayerOrder = 0
            for (let i = 0; i < this.runtime.targets.length; i++) {
                if (!this.runtime.targets[i].isStage && this.runtime.targets[i].sprite.layerOrder > maxLayerOrder) {
                    maxLayerOrder = this.runtime.targets[i].sprite.layerOrder
                }
            }
            target.sprite.layerOrder = maxLayerOrder + 1

            this.runtime.addTarget(target)
            this.runtime.setEditingTarget(target.id)

            this.runtime.emit("SAY", util.target, "say", '')
            console.log('角色已成功添加')
        } else {
            console.error(`Layer group '${group}' not found in renderer._layerGroups`)
        }
 
    } catch (error) {
        console.error('添加角色时出错:', error)
    }
}
```

## 关键点解析

图片的加载与转换：通过 fetch 方法获取图片数据，并使用 canvas 将其绘制为 Base64 格式，确保图片能被 Scratch 识别并处理。

角色的创建与初始化：创建 costume 对象，包含图片的相关信息，并利用 Scratch 的内部 renderer 机制生成角色的皮肤 ID（skinId）。然后，通过创建 sprite 和 target 对象，将角色成功添加到 Scratch 的角色区。

层次管理：通过遍历现有角色，确定新的角色应处于的层次顺序，确保角色在舞台上的显示效果正确。

## 最终的收获

解决这个问题的过程充满了挑战，但也让我更深入地理解了 Scratch 的内部机制。从图片的加载处理，到角色的生成与渲染，每一步都需要细心调试与思考。
通过这次经验，我也更明确了在进行二次开发时，深入了解底层机制的重要性。希望这篇文章能对遇到类似问题的开发者有所帮助。

![生成中](/img/scratch_custom/img-1.png)

![已完成](/img/scratch_custom/img-2.png)

