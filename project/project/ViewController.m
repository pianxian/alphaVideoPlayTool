//
//  ViewController.m
//  project
//
//  Created by 胡伟伟 on 2021/3/6.
//

#import "ViewController.h"
#import <SLMaskVideoPlayerLayer.h>
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<maskVideoPlayDelegate>{
    SLMaskVideoPlayerLayer *_playerLayer;
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _playerLayer = [SLMaskVideoPlayerLayer layer];
    _playerLayer.playDelegate = self;
    _playerLayer.frame = self.view.bounds;
    [self play];
}


-(void)maskVideoDidPlayFinish:(SLMaskVideoPlayerLayer *)playerLayer{
    [_playerLayer removeFromSuperlayer];
}
-(void)play{
    _playerLayer.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"giftId-608a5a20bb58c31a408c7e9e" ofType:@"mp4"]];

    [self.view.layer addSublayer:_playerLayer];
    [_playerLayer play];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self play];

}
@end
