//
//  CustomView.h
//

#import <UIKit/UIKit.h>

@interface CustomView : UIView
{
    CGPoint point;
}

@property(nonatomic) CGPoint point;

- (void)touchesMoved :(NSSet *)touches withEvent : (UIEvent *)event;

@end
