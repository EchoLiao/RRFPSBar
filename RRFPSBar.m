//
//  RRFPSBar.m
//
//  Created by Rolandas Razma on 07/03/2013.
//  Copyright 2013 Rolandas Razma. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "RRFPSBar.h"


@implementation RRFPSBar {
    CADisplayLink          *_displayLink;
    CGFloat                 _historyFPS[320];
    NSUInteger              _historyFPSLength;
    CFTimeInterval          _displayLinkTickTimeLast;
}


#pragma mark -
#pragma mark NSObject


- (id)init {
    if( (self = [super initWithFrame:[[UIApplication sharedApplication] statusBarFrame]]) ){
        _historyFPSLength           = 0;
        _displayLinkTickTimeLast    = CACurrentMediaTime();
        
        [self setWindowLevel: UIWindowLevelStatusBar +1.0f];
        [self setBackgroundColor:[UIColor blackColor]];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick)];
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}


#pragma mark -
#pragma mark UIVIew


- (void)drawRect:(CGRect)rect {
    CGFloat height = rect.size.height;
    CGFloat lowestFPS = 1.0f;
    
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();

    // Draw FPS
    CGContextSetLineWidth(currentContext, 1);
    CGContextSetRGBStrokeColor(currentContext, 1.0f, 0.0f, 0.0f, 1.0f);
    CGContextBeginPath(currentContext);

    CGContextMoveToPoint(currentContext, 0, 0);
    for( NSUInteger i=0; i<=_historyFPSLength; i++ ){
        lowestFPS = MIN(lowestFPS, _historyFPS[i]);
        
        CGContextAddLineToPoint(currentContext, i +1, MAX(height -height *_historyFPS[i], 0));
    }

    CGContextStrokePath(currentContext);
    
    // Draw lowest FPS
    CGContextSetTextDrawingMode(currentContext, kCGTextFill);
    CGContextSetRGBFillColor(currentContext, 1.0f, 0.0f, 0.0f, 1.0f);
    CGContextSelectFont(currentContext, "Helvetica", 10, kCGEncodingMacRoman);
    
    // Flip
    CGContextSetTextMatrix(currentContext, CGAffineTransformMake( 1.0,  0.0,
                                                                  0.0, -1.0,
                                                                  0.0,  0.0));

    NSString *text  = [NSString stringWithFormat:@"low: %.f", lowestFPS *60.0f];
    const char *str = [text UTF8String];
    CGContextShowTextAtPoint(currentContext, 6.0, 18.0, str, strlen(str));

}


#pragma mark -
#pragma mark RRFPSBar


+ (RRFPSBar *)sharedInstance {
    static RRFPSBar *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[RRFPSBar alloc] init];
    });
    return _sharedInstance;
}


- (void)applicationDidBecomeActiveNotification {
    [_displayLink setPaused:NO];
}


- (void)applicationWillResignActiveNotification {
    [_displayLink setPaused:YES];
}


- (void)displayLinkTick {
    
    // Shift up the buffer
    for ( int i = _historyFPSLength; i >= 1; i-- ) {
        _historyFPS[i] = _historyFPS[i -1];
    }
    
    // Store new state
    _historyFPS[0] = roundf(1.0f /(float)(_displayLink.timestamp -_displayLinkTickTimeLast)) /60.0f;

    // Update length if there is more place
	if ( _historyFPSLength < 319 ) _historyFPSLength++;
    
    // Store last timestamp
    _displayLinkTickTimeLast = _displayLink.timestamp;
    
    // We should redraw
    [self setNeedsDisplay];
    
}


@end