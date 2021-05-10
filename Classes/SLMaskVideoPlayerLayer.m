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
}





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
        self.pixelBufferAttributes = @{@"PixelFormatType":@(kCMPixelFormat_32BGRA)};
        self.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:UIApplicationWillResignActiveNotification object:nil];//进入后台结束播放
    }
    return self;
}


/// //进入后台结束播放
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
        dispatch_async(dispatch_get_main_queue(), ^{
    
            AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithAsset:videoAsset];
//            self->_playItem = playItem;
            [self intilizaAudioTacks:self->_muted];
            [self intilizaPlayItem:playItem];
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
      AVMutableAudioMixInputParameters *audioInputParams =
        [AVMutableAudioMixInputParameters audioMixInputParameters];

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
                #else
           
                #endif
                
//                NSLog(@"---error%@",error);
                
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
            [request finishWithImage:outPutImage context:nil];
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


    if (_playDelegate &&[_playDelegate respondsToSelector:@selector(maskVideoDidPlayFinish:)]) {
        [self.playDelegate maskVideoDidPlayFinish:self];
    }


}
-(void)clear{
    [self pause];
    [_videoPlayer.currentItem cancelPendingSeeks];
    [_videoPlayer.currentItem.asset cancelLoading];
    [_videoPlayer replaceCurrentItemWithPlayerItem:nil];
    _videoPlayer = nil;

    if (_playItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playItem];
        _playItem = nil;

    }
    [self removeFromSuperlayer];
}
/// video begain play
-(void)play{
    [self initSession];
    [_videoPlayer play];
}

/// 设置Session
-(void)initSession{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];
}

/// video pause
-(void)pause{
    [_videoPlayer pause];
}



@end
