//
//  SLMaskVideoPlayerLayer.m
//  SangoLive
//
//  Created by 胡伟伟 on 2021/3/4.
//  Copyright © 2021 Sango. All rights reserved.
//

#import "SLMaskVideoPlayerLayer.h"



@interface SLMaskVideoPlayerLayer (){
    NSInteger _playCount;
    dispatch_queue_t _loadValuesAsynchronouslyQueue_t;
}

@property (nonatomic,assign) id observer;

@end

@implementation SLMaskVideoPlayerLayer
-(AVPlayer *)videoPlayer{
    if (!_videoPlayer) {
        _videoPlayer = [[AVPlayer alloc] init];
    }
    return _videoPlayer;
}




//-(Class)class{
//    return self.videoPlayer;
//}
/// 初始化
-(instancetype)init{
    if (self = [super init]) {
        _muted = NO;
        _loop = 1;
        _maskDirection = alphaVideoMaskDirectionLeftToRight;
        _loadValuesAsynchronouslyQueue_t = dispatch_queue_create("loadValuesAsynchronously.loadValuesAsynchronously.mp4", DISPATCH_QUEUE_CONCURRENT);
        self.pixelBufferAttributes = @{@"PixelFormatType":@(kCMPixelFormat_32BGRA)};
        self.videoGravity = AVLayerVideoGravityResizeAspectFill;
        NSNotificationCenter *noficationCenter = [NSNotificationCenter defaultCenter];

        [noficationCenter addObserver:self selector:@selector(stopPlay) name:UIApplicationWillResignActiveNotification object:nil];//进入后台结束播放
        [noficationCenter addObserver:self selector:@selector(silenceSecondaryAudioHint) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
        [noficationCenter addObserver:self selector:@selector(mediaServicesWereLost) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
        [noficationCenter addObserver:self selector:@selector(mediaServicesWereLost) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
        [noficationCenter addObserver:self selector:@selector(sessionInterruption) name:AVAudioSessionInterruptionNotification object:nil];
        [noficationCenter addObserver:self selector:@selector(failedToEndTime) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        [noficationCenter addObserver:self selector:@selector(playBackStalled) name:AVPlayerItemPlaybackStalledNotification object:nil];
//耳机事件
        [noficationCenter addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    }
    return self;
}

-(void)handleRouteChange:(NSNotification *)notifi{
    AVAudioSession *session = [AVAudioSession sharedInstance];
       NSString *seccReason = @"";
       NSInteger reason = [[[notifi userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
       switch (reason) {
           case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
               seccReason = @"The route changed because no suitable route is now available for the specified category.";
               break;
           case AVAudioSessionRouteChangeReasonWakeFromSleep:
               seccReason = @"The route changed when the device woke up from sleep.";
               break;
           case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
               seccReason = @"The output route configuration changed.";
               break;
           case AVAudioSessionRouteChangeReasonOverride:
               seccReason = @"The output route was overridden by the app.";
               break;
           case AVAudioSessionRouteChangeReasonCategoryChange:{
               seccReason = @"The output route category changed.";
           }
               break;
           case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:{

               if (self.isPlaying){
                   [self resum];
                   NSLog(@"恢复播放");
               }
           }
               break;
           case AVAudioSessionRouteChangeReasonNewDeviceAvailable:{
               if (self.isPlaying){
                   [self resum];
                   NSLog(@"恢复播放");
               }

           }
               break;
           case AVAudioSessionRouteChangeReasonUnknown:{
               seccReason = [NSString stringWithFormat:@"AVAudioSession Route change Reason is %ld (oldUnavailiable:2,newDevice:1,unknown:0)",(long)reason];
           }
               break;
           default:
               seccReason = [NSString stringWithFormat:@"The reason invalidate enum value : %ld",(long)reason];
               break;
       }
       
       AVAudioSessionRouteDescription *currentRoute = session.currentRoute;
       for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
           if ([output.portType isEqualToString:AVAudioSessionPortBluetoothA2DP] || [output.portType isEqualToString:AVAudioSessionPortBluetoothLE ]|| [output.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) { //耳机
               NSLog(@"耳机播放");
           }else {
               NSLog(@"扬声器播放");
           }
       }
       NSLog(@"handleRouteChange reason is %@,mode:%@,category:%@", seccReason,session.mode,session.category);

}
//耳机拔插
-(void)silenceSecondaryAudioHint{
    NSLog(@"AVAudioSessionSilenceSecondaryAudioHintNotification");
    if (self.isPlaying)[self resum];
}
//媒体服务器终止、重启
-(void)mediaServicesWereLost{
    NSLog(@"AVAudioSessionMediaServicesWereLostNotification");
    if (self.isPlaying)[self stopPlay];

}
//音频中断
-(void)sessionInterruption{
    NSLog(@"AVAudioSessionInterruptionNotification");
    if (self.isPlaying)[self stopPlay];
}
//播放失败
-(void)failedToEndTime{
    if (self.isPlaying)[self stopPlay];
    NSLog(@"AVPlayerItemFailedToPlayToEndTimeNotification");
}
//异常中断
-(void)playBackStalled{
    NSLog(@"AVPlayerItemPlaybackStalledNotification");
    if (self.isPlaying)[self stopPlay];
}


//进入后台结束播放
-(void)stopPlay{
    [self didFinishPlay];
}


/// SetterVideoURL
/// @param videoURL 视频路径
-(void)setVideoURL:(NSURL *)videoURL{
    _videoURL = videoURL;
    self.player = self.videoPlayer;

    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    [videoAsset loadValuesAsynchronouslyForKeys:@[@"duration",@"tracks"] completionHandler:^{
        dispatch_async(self->_loadValuesAsynchronouslyQueue_t, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
        
                AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithAsset:videoAsset];
                _playItem = playItem;

                [self intilizaAudioTacks:self->_muted];
                [self intilizaPlayItem:playItem];
            });
        });
    }];
}
-(void)setMuted:(BOOL)muted{
    _muted = muted;
    if (_playItem) {
        [self intilizaAudioTacks:muted];
    }
}

/// 设置音轨
/// @param muted 是否静音
-(void)intilizaAudioTacks:(BOOL)muted{
   
    NSArray *audioTracks = [_playItem.asset tracksWithMediaType:AVMediaTypeAudio];

    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];

        [audioInputParams setVolume:muted ? 0:[AVAudioSession sharedInstance].outputVolume atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }

    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [_playItem setAudioMix:audioMix];
}

/// 设置  playerItem
/// @param playItem playItem
-(void)intilizaPlayItem:(AVPlayerItem *)playItem{
    [_videoPlayer seekToTime:kCMTimeZero];
    [self intilizaPlayItemComposition:playItem];
    [self intilizaItemObserver:playItem];
    [_videoPlayer replaceCurrentItemWithPlayerItem:playItem];
}

/// 设置 AVMutableVideoComposition
/// @param playItem playItem
-(void)intilizaPlayItemComposition:(AVPlayerItem *)playItem{
    //获取轨道
    NSArray <AVAssetTrack *> *assetTracks = playItem.asset.tracks;
#if DEBUG
    NSAssert(assetTracks, @"NO tracks please check video source");
#else
    if(!assetTracks.count)return;
#endif

    CGSize videoSize = CGSizeZero;
    switch (_maskDirection) {
        case alphaVideoMaskDirectionLeftToRight:
        case alphaVideoMaskDirectionRightToLeft:{
            videoSize = CGSizeMake(assetTracks.firstObject.naturalSize.width/2.f, assetTracks.firstObject.naturalSize.height);
        }
            break;
        case alphaVideoMaskDirectionTopToBottom:
        case alphaVideoMaskDirectionBottomToTop:
        {
            videoSize =   CGSizeMake(assetTracks.firstObject.naturalSize.width, assetTracks.firstObject.naturalSize.height/2.f);
        }
        default:
            break;
    }
#if DEBUG
    NSAssert(videoSize.width && videoSize.height, @"videoSize can't be zero");
#else
    if (!videoSize.width ||!videoSize.height) return;
#endif

    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:playItem.asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        //source rect this is you will show
        CGRect sourceRect = (CGRect){0,0,videoSize.width,videoSize.height};
        CGRect alphaRect = CGRectZero;
        
        CGFloat dx;
        CGFloat dy;
        switch (self->_maskDirection) {
            case alphaVideoMaskDirectionLeftToRight:
            case alphaVideoMaskDirectionRightToLeft:{
                alphaRect = CGRectOffset(sourceRect, videoSize.width, 0);
                dx = -sourceRect.size.width;
                dy = 0;
            }
                break;
            case alphaVideoMaskDirectionTopToBottom:
            case alphaVideoMaskDirectionBottomToTop:
            {
                alphaRect = CGRectOffset(sourceRect, 0, videoSize.height);
                dx = 0;
                dy = -sourceRect.size.height;
            }
            default:
                break;
        }
     
        
        if (@available(iOS 11.0, *)) {
            if (!videoKernel) {
                NSURL *kernelURL = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"metallib"];
                NSError *error;
                NSData *kernelData = [NSData dataWithContentsOfURL:kernelURL];
                videoKernel = [CIColorKernel kernelWithFunctionName:@"maskVideoMetal" fromMetalLibraryData:kernelData error:&error];
                #if DEBUG
                NSAssert(!error, @"%@",error);
                #endif
            }
        } else {
            if (!videoKernel) {
                videoKernel = [CIColorKernel kernelWithString:@"kernel vec4 alphaFrame(__sample s, __sample m) {return vec4(s.rgb, m.r);}"];
            }
        }
        
        
        CIImage *inputImage;
        CIImage *maskImage;
        switch (self->_maskDirection) {
            case alphaVideoMaskDirectionLeftToRight:{
                inputImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                
                maskImage = [request.sourceImage imageByCroppingToRect:sourceRect];
            }
                break;
            case alphaVideoMaskDirectionRightToLeft:{
                inputImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                maskImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
            }
                break;
            case alphaVideoMaskDirectionTopToBottom:{
                inputImage = [request.sourceImage imageByCroppingToRect:sourceRect];
                maskImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
            }
                break;
            case alphaVideoMaskDirectionBottomToTop:
            {

                
                inputImage = [[request.sourceImage imageByCroppingToRect:alphaRect] imageByApplyingTransform:CGAffineTransformMakeTranslation(dx, dy)];
                
                maskImage = [request.sourceImage imageByCroppingToRect:sourceRect];
            }
            default:
                break;
        }
        if (inputImage && maskImage) {
            CIImage *outPutImage = [videoKernel applyWithExtent:inputImage.extent arguments:@[(id)inputImage,(id)maskImage]];
            if (outPutImage) {
                [request finishWithImage:outPutImage context:nil];
            }
        }

    }];
    videoComposition.renderSize = videoSize;
    playItem.videoComposition = videoComposition;
    playItem.seekingWaitsForVideoCompositionRendering = YES;
}
-(void)videoDidPlayFihisn{
    [_videoPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            if (self->_loop <=0) {//play cycle
                [self play];
            }else if (self->_loop ==1){//play Once
                [self didFinishPlay];
            }else{
                self->_playCount ++;
                if (self->_playCount>=self->_loop) {
                    self->_playCount = 0;
                    [self didFinishPlay];

                    return;
                }
                [self play];
            }
        }else{
            [self clear];
            if (self->_playDelegate &&[self->_playDelegate respondsToSelector:@selector(maskVideoDidPlayFinish:)]) {
                [self.playDelegate maskVideoDidPlayFinish:self];
            }
        }
        
    }];
}
/// 设置observer
/// @param playItem playItem
-(void)intilizaItemObserver:(AVPlayerItem *)playItem{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidPlayFihisn) name:AVPlayerItemDidPlayToEndTimeNotification object:playItem];
}

-(void)didFinishPlay{
    NSLog(@"play Finish");
    [self clear];
    if (_playDelegate &&[_playDelegate respondsToSelector:@selector(maskVideoDidPlayFinish:)]) [self.playDelegate maskVideoDidPlayFinish:self];
    
    if (_observer) [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}
-(void)clear{
    [self pause];
    [_videoPlayer.currentItem cancelPendingSeeks];
    [_videoPlayer.currentItem.asset cancelLoading];
    [_videoPlayer replaceCurrentItemWithPlayerItem:nil];
    _videoPlayer = nil;

    if (_playItem) [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playItem];
        _playItem = nil;

    [self removeFromSuperlayer];
}
/// video begain play
-(void)play{
    dispatch_barrier_sync(_loadValuesAsynchronouslyQueue_t, ^{
        _playing = YES;
        [self initSession];
        [_videoPlayer play];
        _observer = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            _currentTime = time;
        }];
    });
}

/// 设置Session
-(void)initSession{
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];
}

/// video pause
-(void)pause{
    _playing = NO;
    [_videoPlayer pause];
}

/// video resum
-(void)resum{
    [_videoPlayer seekToTime:_currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"seek到指定时间重新播放");
            [_videoPlayer play];
        }else{
            [self videoDidPlayFihisn];
        }
    }];
}


@end
