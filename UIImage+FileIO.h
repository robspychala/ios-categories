#import <UIKit/UIKit.h>

@interface UIImage (FileIO)
- (void)writeImageToFile:(NSString*)fileName;
+ (UIImage*)imageFromFile:(NSString*)fileName;
@end