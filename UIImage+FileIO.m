#import "UIImage+FileIO.h"
//#import "UIScreen+Scale.h"

void FileIOProviderReleaseData(void *info, const void *data, size_t size)
{
    if (data) {
        free((char*) data);
    }
}

@implementation UIImage(FileIO)

- (void)writeImageToFile:(NSString*)fileName 
{
    
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
    
    const UInt8 *buffer = CFDataGetBytePtr(data);
    SInt32 bufferLength = CFDataGetLength(data);

    FILE *file = fopen([fileName UTF8String], "wb");
    if (!file) {
        NSLog(@"error opening file w: %@", fileName);
        return;
    }

    CGSize s = self.size;
    fwrite(&s, 1, sizeof(struct CGSize), file);

    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.CGImage);
    fwrite(&bitmapInfo, 1, sizeof(CGBitmapInfo), file);

    int bitsPerPixel = CGImageGetBitsPerPixel(self.CGImage);
    fwrite(&bitsPerPixel, 1, sizeof(int), file);

    int bytesPerRow = CGImageGetBytesPerRow(self.CGImage);
    fwrite(&bytesPerRow, 1, sizeof(int), file);

    fwrite(buffer, 1, bufferLength, file);
    
    fclose (file);

    CFRelease(data);
    
}

/* 
 * saves the size of the image in the 1st few bytes
 */
+ (UIImage*)imageFromFile:(NSString*)fileName
{
	
	FILE *file = fopen([fileName UTF8String], "r");
	if (!file) {
		NSLog(@"error opening file r: %@", fileName);
        return nil;
	}
	
	fseek (file , 0, SEEK_END);
	long lSize = ftell(file);
	rewind (file);
	
	// allocate memory to contain the image part of the file:
	int imageByteSize = sizeof(char)*lSize - sizeof(struct CGSize) - sizeof(CGBitmapInfo) - sizeof(int) - sizeof(int);
	char *imageBuffer = (char*) malloc (imageByteSize);
	if (imageBuffer == NULL) {
		NSLog(@"error reading file!");
	}
	
	CGSize imageSize = CGSizeZero;
	fread(&imageSize, sizeof(struct CGSize),1,file);
	
	CGBitmapInfo bitmapInfo = 0;
	fread(&bitmapInfo, sizeof(CGBitmapInfo), 1, file);
	
	int bitsPerPixel = 0;
	fread(&bitsPerPixel, sizeof(int), 1, file);
	
	int bytesPerRow = 0;
	fread(&bytesPerRow, sizeof(int), 1, file);	
	
	int result = fread (imageBuffer, 1, imageByteSize, file);
	if (result != imageByteSize) {
		NSLog(@"error reading file!");
	}
	
	CGDataProviderRef imageDataProvider = CGDataProviderCreateWithData(NULL, imageBuffer, 
                                                                       imageByteSize, 
                                                                       FileIOProviderReleaseData);
    
    imageSize = CGSizeMake(imageSize.width, imageSize.height);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(
                                        imageSize.width,
                                        imageSize.height,
                                        8,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpace,
                                        bitmapInfo,
                                        imageDataProvider,
                                        NULL,
                                        true,
                                        kCGRenderingIntentDefault);
    
    CGDataProviderRelease(imageDataProvider);
    
    UIImage *img = [UIImage imageWithCGImage:cgImage];
    
    fclose(file);

    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    return img;
	
}

@end
