//
//  IntroController.m
//

#import "IntroController.h"

@interface IntroController ()

@end

@implementation IntroController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView * page1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page1.png"]];
    UIImageView * page2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page2.png"]];
    UIImageView * page3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page3.png"]];

    NSArray *pages = [NSArray arrayWithObjects:page1,page2,page3, nil];
    for (int i = 0; i < pages.count; i++) {
        CGRect frame;
        frame.origin.x = self.scrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self.scrollView.frame.size;
        
        UIView *subview = [[UIView alloc] initWithFrame:frame];
        [subview addSubview:[pages objectAtIndex:i]];
        [self.scrollView addSubview:subview];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * pages.count, self.scrollView.frame.size.height);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}



- (IBAction)changePage:(id)sender {
    CGRect frame;
    frame.origin.x = self.scrollView.frame.size.width * self.pageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.scrollView.frame.size;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

- (IBAction)closeController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
