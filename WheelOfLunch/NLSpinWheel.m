//
//  NLSpinWheel.m
//  WheelOfLunch
//
//  Created by Nick Lupinetti on 7/22/12.
//  Copyright (c) 2012 Nick Lupinetti. All rights reserved.
//

#import "NLSpinWheel.h"

@interface NLSpinWheel ()

@property (nonatomic) CGPoint contactPoint;

- (void)handlePan:(UIPanGestureRecognizer*)pan;
- (float)radiansFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2 toPoint:(CGPoint)point3;

@end

@implementation NLSpinWheel

@synthesize contactPoint;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:147.0/255.0
                                               green:178.0/255.0
                                                blue:  1.0
                                               alpha:  1.0];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
        [pan addTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.contactPoint = [touch locationInView:self];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    BOOL began = pan.state == UIGestureRecognizerStateBegan;
    BOOL changed = pan.state == UIGestureRecognizerStateChanged;
    BOOL ended = pan.state == UIGestureRecognizerStateEnded;
    
    if (began || changed) {
        CGPoint touchPoint = [pan locationInView:self];
        
        CGPoint center = self.center;
        center.x -= self.frame.origin.x;
        center.y -= self.frame.origin.y;
        
        float angle = [self radiansFromPoint:self.contactPoint toPoint:center toPoint:touchPoint];
        
        self.transform = CGAffineTransformRotate(self.transform, angle);
    }
    if (ended) {
        NSLog(@"velocity: %@", NSStringFromCGPoint([pan velocityInView:self]));
        
    }
}

- (float)radiansFromPoint:(CGPoint)p1 toPoint:(CGPoint)p2 toPoint:(CGPoint)p3 {
    CGPoint v1 = CGPointMake(p1.x - p2.x, p1.y - p2.y);
    CGPoint v2 = CGPointMake(p3.x - p2.x, p3.y - p2.y);
    
    float magV1 = sqrtf(v1.x * v1.x + v1.y * v1.y);
    float magV2 = sqrtf(v2.x * v2.x + v2.y * v2.y);
    
    float cosine = (v1.x * v2.x + v1.y * v2.y) / (magV1 * magV2);
    float arccos = acosf(cosine);
    
    if (cosine >= 1) {
        arccos = 0;
    }
    if (cosine <= -1) {
        arccos = M_PI;
    }
    
    float cross = v1.x * v2.y - v1.y * v2.x;
    
    return cross < 0 ? -arccos : arccos;
}


@end
