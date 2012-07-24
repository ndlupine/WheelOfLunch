//
//  NLSpinWheel.m
//  WheelOfLunch
//
//  Created by Nick Lupinetti on 7/22/12.
//  Copyright (c) 2012 Nick Lupinetti. All rights reserved.
//

#import "NLSpinWheel.h"

#define Vxk(vec, k) CGPointMake(vec.x * k, vec.y * k)
#define V_k(vec, k) CGPointMake(vec.x / k, vec.y / k)
#define PpP(p1, p2) CGPointMake(p1.x + p2.x, p1.y + p2.y)
#define PmP(p1, p2) CGPointMake(p1.x - p2.x, p1.y - p2.y)
#define VpV(v1, v2) PpP(v1, v2)
#define VmV(v1, v2) PmP(v1, v2)
#define VEC(p1, p2) VmV(p2, p1)
#define MAG(vector) sqrtf(vector.x * vector.x + vector.y * vector.y)
#define STR(aPoint) NSStringFromCGPoint(aPoint)

#define kDecelerationRate 0.4

typedef enum {
    NLSpinnerDirectionClockwise,
    NLSpinnerDirectionCounterclockwise
}NLSpinnerDirection;

@interface NLSpinWheel ()

@property (nonatomic) CGPoint contactPoint;
@property (nonatomic) float angularVelocity;
@property (nonatomic, retain) NSTimer *decelerationTimer;
@property (nonatomic, retain) NSDate *dateOfLastTimerTick;
@property (nonatomic) NLSpinnerDirection currentDirection;

- (void)handlePan:(UIPanGestureRecognizer*)pan;
- (float)radiansFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2 toPoint:(CGPoint)point3;
- (void)beginDecelerating;
- (void)decelerateWithTimer:(NSTimer*)timer;
- (void)haltDecelerating;

@end


@implementation NLSpinWheel

@synthesize contactPoint;
@synthesize angularVelocity;
@synthesize decelerationTimer;
@synthesize dateOfLastTimerTick;
@synthesize currentDirection;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        UIImageView *spinnerView = [[UIImageView alloc] initWithFrame:self.bounds];
        spinnerView.image = [UIImage imageNamed:@"wheel"];
        spinnerView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:spinnerView];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
        [pan addTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self haltDecelerating];
    
    UITouch *touch = [touches anyObject];
    self.contactPoint = [touch locationInView:self.superview];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    BOOL began = pan.state == UIGestureRecognizerStateBegan;
    BOOL changed = pan.state == UIGestureRecognizerStateChanged;
    BOOL ended = pan.state == UIGestureRecognizerStateEnded;
    
    CGPoint touchPoint = [pan locationInView:self.superview];
    
    if (began || changed) {
        float angle = [self radiansFromPoint:self.contactPoint toPoint:self.center toPoint:touchPoint];
        
        self.currentDirection = angle < 0 ? NLSpinnerDirectionClockwise : NLSpinnerDirectionCounterclockwise;
        
        self.transform = CGAffineTransformRotate(self.transform, angle);
        
        self.contactPoint = touchPoint;
    }
    else if (ended) {
//        NSLog(@"velocity: %@", NSStringFromCGPoint([pan velocityInView:self.superview]));
        CGPoint p1p2 = [pan velocityInView:self.superview];
        CGPoint p2 = touchPoint;
        CGPoint p1 = VmV(p2, p1p2);
        
//        NSLog(@"p1: %@, p2: %@", STR(p1),STR(p2));
        
        CGPoint v1 = VEC(self.center, p1);
        CGPoint v2 = VEC(self.center, p2);
        float mag1 = MAG(v1);
        float mag2 = MAG(v2);
        
        float minMag = fminf(mag1, mag2);
        
//        NSLog(@"v1: %@, v2: %@", STR(v1), STR(v2));
        v1 = Vxk(V_k(v1, mag1), minMag);
        v2 = Vxk(V_k(v2, mag2), minMag);
//        NSLog(@"v1: %@, v2: %@", STR(v1),STR(v2));
        
        p1 = VpV(self.center, v1);
        p2 = VpV(self.center, v2);
//        NSLog(@"p1: %@, p2: %@", STR(p1),STR(p2));
        CGPoint velocity = VEC(p1, p2);
        
//        NSLog(@"adjusted velocity: %@", STR(velocity));
        
        float directionalFactor = self.currentDirection == NLSpinnerDirectionClockwise ? -1 : 1;
        float speed = MAG(velocity) + MAG(p1p2) / 10;
        self.angularVelocity = speed / minMag * directionalFactor;
        
        [self beginDecelerating];
    }
}

- (float)radiansFromPoint:(CGPoint)p1 toPoint:(CGPoint)p2 toPoint:(CGPoint)p3 {
    CGPoint v1 = VEC(p2, p1);
    CGPoint v2 = VEC(p2, p3);
    
    float cosine = (v1.x * v2.x + v1.y * v2.y) / (MAG(v1) * MAG(v2));
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

- (void)beginDecelerating {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.0167 target:self selector:@selector(decelerateWithTimer:) userInfo:nil repeats:YES];
    self.decelerationTimer = timer;
    self.dateOfLastTimerTick = [NSDate date];
}

- (void)decelerateWithTimer:(NSTimer *)timer {
    NSDate *now = [NSDate date];
    NSTimeInterval deltaT = [now timeIntervalSinceDate:self.dateOfLastTimerTick];
    
    float deltaDirection = self.angularVelocity < 0 ? 1 : -1;
    float deltaV = deltaT * kDecelerationRate * deltaDirection;
    float newVelocity = self.angularVelocity + deltaV;
    
    BOOL velocitySignsMatch = copysignf(1.0, newVelocity) == copysignf(1.0, self.angularVelocity);
    
    if (!velocitySignsMatch) {
        [self haltDecelerating];
    }
    else {
        float deltaAngle = self.angularVelocity * deltaT;
        
        self.transform = CGAffineTransformRotate(self.transform, deltaAngle);
        
        self.dateOfLastTimerTick = now;
        self.angularVelocity = newVelocity;
    }
    
    self.dateOfLastTimerTick = now;
}

- (void)haltDecelerating {
    self.angularVelocity = 0;
    [self.decelerationTimer invalidate];
    self.dateOfLastTimerTick = nil;
}


@end
