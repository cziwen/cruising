# 已知问题 (Known Issues)

本文档用于记录在测试过程中发现的问题、Bug 以及待优化的设计点，以便后续跟踪和修复。


UI显示 (已修复)：
1. 在 酒馆 tavern 中，英文语言里，每个 crew 的 姓 和 名之间没有空格。(已修复：引入了 nameSeparator 配置)
2. Market 页面底部 的 平衡报价（balance trade）和 确认交易 （Confirm Trade）有点overflow了。(已修复：缩短了按钮文本，并引入了动态 Font 大小和自动换行逻辑)
3. shipyard 里的升级选项 没有做 本地化+多语言（英语），在英语下还是显示中文。且升级按钮的文字也有overflow。(已修复：完成了 Shipyard 本地化，按钮仅显示金币报价以节省空间)
4. 按钮overflow的我希望通过动态 font 大小，和根据这些按钮背景大小的来给文字设置padding。(已修复：PaperButton 实现了基于字数和行数的动态缩放逻辑)