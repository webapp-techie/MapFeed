//
//  CustomView.m
//

#import "CustomView.h"

@implementation CustomView

@synthesize point;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)touchesMoved :(NSSet *)touches withEvent : (UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    self.point = [touch locationInView:[self superview]];
}


@end
