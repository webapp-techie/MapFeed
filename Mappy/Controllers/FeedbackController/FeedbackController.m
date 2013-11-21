//
//  FeedbackController.m
//

#import "FeedbackController.h"

@interface FeedbackController ()

@end

@implementation FeedbackController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performBackAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)performSubmitAction:(id)sender {
}
@end
