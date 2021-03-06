//
//  ViewController.m
//  project
//
//  Created by 胡伟伟 on 2021/3/6.
//

#import "ViewController.h"
#import <SLMaskVideoPlayerLayer.h>

@interface ViewController ()<maskVideoPlayDelegate>{
    SLMaskVideoPlayerLayer *_playerLayer;
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _playerLayer = [SLMaskVideoPlayerLayer layer];
    _playerLayer.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"手表" ofType:@"mp4"]];
    _playerLayer.playDelegate = self;
    [self.view.layer addSublayer:_playerLayer];
    _playerLayer.frame = self.view.bounds;
    [_playerLayer play];
}
-(void)maskVideoDidPlayFinish:(SLMaskVideoPlayerLayer *)playerLayer{
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_playerLayer play];
}
@end
