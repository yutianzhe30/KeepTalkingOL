## This is the AGENTS.md file

## This is an online async puzzel solving game like keep talking and nobody explodes


1. Help me design the game (2D/3D? I think 2D is easier to implement)
2. maybe we start from 2 simple elements: a bomb timer and a "cut the wire" module


## 几种模块

## 有一个平衡模块 已完成
- 炸弹的下半部分，有一个小球，拆弹玩家需要通过倾斜炸弹（wasd或上下左右键，让小球保持在矩形中间）
- 在拆弹过程中需要时刻保持此模块不”失败“
- 如果小球触碰到矩形的边框，则失败
- 在初始时随机赋予小球一个比较小的初始速度，方向随机，越靠近边框，速度越大


## 计时器模块
- 倒计时，时间到则失败
- 开始播放的1秒1次的倒计时
- 最后30s时1秒播放2次“滴滴”声
- 这里能不能用seg7 字体

## 剪线模块
- 根据一定的规则，玩家剪线需要满足一定的顺序（

## 按钮模块
- 有很多奇怪的字符，例如俄语，日语，伽罗语，中文，藏语字母等等
- 创建多个列表，每个大概10个左右 ，互相之间可以有2-3个重复字符
- 从1个列表中挑选4个 做成2x2的按钮，玩家需要找出在哪个列表中并按顺序点击以解锁

## TODO
-  add a led on each module if correctly sovled, show green, if wrong flash red