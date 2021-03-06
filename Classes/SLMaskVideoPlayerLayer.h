//
//  SLMaskVideoPlayerLayer.h
//  SangoLive
//
//  Created by 胡伟伟 on 2021/3/4.
//  Copyright © 2021 Sango. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SLAlphaVideoDefines.h"

NS_ASSUME_NONNULL_BEGIN


@class SLMaskVideoPlayerLayer;

@protocol maskVideoPlayDelegate <NSObject>

@optional
-(void)maskVideoDidPlayFinish:(SLMaskVideoPlayerLayer *)playerLayer;


@end

@interface SLMaskVideoPlayerLayer : AVPlayerLayer


/// 是否静音
@property (nonatomic,assign) BOOL muted;

/// 循环次数 默认为1次 <=0为无限循环
@property (nonatomic,assign) NSInteger loop;

/// 合成方向 默认为 白幕在左
@property (nonatomic,assign) alphaVideoMaskDirection maskDirection;

/// 视频路径 支持URL 下载播放
@property (nonatomic,strong) NSURL *videoURL;


/// playDelegate
@property (nonatomic,weak) id<maskVideoPlayDelegate>playDelegate;

/// video begain play
-(void)play;

/// video pause
-(void)pause;
/// 设置Session
-(void)initSession;
-(void)clear;
@end

NS_ASSUME_NONNULL_END
