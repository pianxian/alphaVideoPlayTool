# alphaVideoPlayTool


透明视频播放工具类

基于苹果Metal框架给带alpha通道的视频添加滤镜效果实现合成透明视频效果

cocopods 导入 pod 'alphaVideoPlayTool'




使用方法
导入 #import <SLMaskVideoPlayerLayer.h>


_playerLayer = [SLMaskVideoPlayerLayer layer];

_playerLayer.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"手表" ofType:@"mp4"]];

_playerLayer.playDelegate = self;

[self.view.layer addSublayer:_playerLayer];

_playerLayer.frame = self.view.bounds;

[_playerLayer play];
    
还需要在项目中添加 metal文件 filter.metal 放在demo中 
下载后拖进项目并在buildSetting 中搜索 metal 
在 Other Metal Linker Flags 和 Other Metal Compiler Flags中添加设置-fcikernel
![WX20210306-150744](https://user-images.githubusercontent.com/16642672/110198581-86fb3d00-7e8e-11eb-93c2-e43598c0db19.png)
