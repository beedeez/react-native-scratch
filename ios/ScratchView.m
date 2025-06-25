#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ScratchViewTools.h"
#import "ScratchView.h"

@implementation ScratchView

-(id)init
{
  self = [super init];
  self.userInteractionEnabled = true;
  self.exclusiveTouch = true;
  return self;
}

-(void)dealloc
{
  // Clean up resources
  image = nil;
  backgroundColorImage = nil;
  path = nil;
  grid = nil;
}

-(id) initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.multipleTouchEnabled = NO;
    self.userInteractionEnabled = true;
    self.exclusiveTouch = true;
  }
  return self;
}


- (void)layoutSubviews {
    [self reset];
    [super layoutSubviews];
}

-(void) setPlaceholderColor:(NSString *)colorString
{
  @try {
    self->placeholderColor = [ScratchViewTools colorFromHexString:colorString];
  }
  @catch (NSException *exception) {
    NSLog(@"placeholderColor error: %@", exception.reason);
  }
}

-(void) setImageUrl:(NSString *)url
{
  imageUrl = url;
}

// Deprecated
-(void) setLocalImageName: (NSString *)imageName
{
    resourceName = imageName;
}

-(void) setResourceName: (NSString *)resourceName
{
    self->resourceName = resourceName;
}

-(void) setResizeMode: (NSString * )resizeMode
{
  if (resizeMode == nil) {
    return;
  }
  self->resizeMode = [resizeMode lowercaseString];
  self.layer.masksToBounds = YES;
}

-(void) setThreshold: (float)value
{
  threshold = value;
}

-(void) setBrushSize: (float)value
{
  brushSize = value;
}

-(void)loadImage
{
  UIColor *backgroundColor = placeholderColor != nil ? placeholderColor : [UIColor grayColor];
  self->backgroundColorImage = [ScratchViewTools createImageFromColor:backgroundColor];
  [self setImage:backgroundColorImage];
  if (imageUrl != nil) {
      NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString: imageUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          if (data) {
              self->image = [UIImage imageWithData:data];
          } else {
            image = backgroundColorImage;
          }
          dispatch_sync(dispatch_get_main_queue(), ^{
            [self drawImageStart];
            [self drawImageEnd];
            [self reportImageLoadFinished: data ? true : false];
          });
      }];
      [task resume];
  } else if (resourceName != nil) {
      image = [UIImage imageNamed:resourceName];
      if (image == nil) {
          image = backgroundColorImage;
      }
      [self drawImageStart];
      [self drawImageEnd];
      [self reportImageLoadFinished: true];
  } else {
    image = backgroundColorImage;
    [self drawImageStart];
    [self drawImageEnd];
    [self reportImageLoadFinished: true];
  }
}

-(void) reset {
  // Use bounds instead of frame for better orientation handling
  minDimension = self.bounds.size.width > self.bounds.size.height ? self.bounds.size.height: self.bounds.size.width;
  brushSize = brushSize > 0 ? brushSize : minDimension / 10.0f;
  brushSize = MAX(1, MIN(100, brushSize));
  threshold = threshold > 0 ? threshold : 50;
  threshold = MAX(1, MIN(100, threshold));
  path = nil;
  [self loadImage];
  [self initGrid];
  [self reportScratchProgress];
  [self reportScratchState];
}

-(void) initGrid
{
  gridSize = MAX(MIN(ceil(minDimension / brushSize), 29), 9);
  grid = [[NSMutableArray alloc] initWithCapacity: gridSize];
  for (int x = 0; x < gridSize; x++)
  {
    [grid insertObject:[[NSMutableArray alloc] init] atIndex:x];
    for (int y = 0; y < gridSize; y++)
    {
        [[grid objectAtIndex:x] addObject:@(YES)];
    }
  }
  clearPointsCounter = 0;
  cleared = false;
  scratchProgress = 0;
}

-(void) updateGrid: (CGPoint)point
{
  // Use bounds instead of frame for better orientation handling
  float viewWidth = self.bounds.size.width;
  float viewHeight = self.bounds.size.height;

  // Ensure point is within bounds regardless of orientation
  CGPoint normalizedPoint = point;
  normalizedPoint.x = MAX(MIN(normalizedPoint.x, viewWidth), 0);
  normalizedPoint.y = MAX(MIN(normalizedPoint.y, viewHeight), 0);

  int pointInGridX = roundf((normalizedPoint.x / viewWidth) * (gridSize - 1.0f));
  int pointInGridY = roundf((normalizedPoint.y / viewHeight) * (gridSize - 1.0f));

  // Additional bounds checking for grid indices
  pointInGridX = MAX(0, MIN(pointInGridX, (int)gridSize - 1));
  pointInGridY = MAX(0, MIN(pointInGridY, (int)gridSize - 1));

  if ([[[grid objectAtIndex:pointInGridX] objectAtIndex: pointInGridY] boolValue]) {
    [[grid objectAtIndex:pointInGridX] replaceObjectAtIndex: pointInGridY withObject: @(NO)];
    clearPointsCounter++;
    scratchProgress = ((float)clearPointsCounter) / (gridSize*gridSize) * 100.0f;
    [self reportScratchProgress];
  }
}

-(void) drawImageStart {
  // Use bounds instead of frame for better orientation handling
  CGSize selfSize = self.bounds.size;
  CGSize imgSize = image.size;
  CGFloat scale = image.scale;
  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);

  if (!imageTakenFromView) {
    [backgroundColorImage drawInRect:CGRectMake(0, 0, selfSize.width, selfSize.height)];
    int offsetX = 0;
    int offsetY = 0;
    float imageAspect = imgSize.width / imgSize.height;
    float viewAspect = selfSize.width / selfSize.height;
    if ([resizeMode isEqualToString:@"cover"]) {
      if (imageAspect > viewAspect) {
          offsetX = (int) (((selfSize.height * imageAspect) - selfSize.width) / 2.0f);
      } else {
          offsetY = (int) (((selfSize.width / imageAspect) - selfSize.height) / 2.0f);
      }
    } else if ([resizeMode isEqualToString:@"contain"]) {
      if (imageAspect < viewAspect) {
            offsetX = (int) (((selfSize.height * imageAspect) - selfSize.width) / 2.0f);
        } else {
            offsetY = (int) (((selfSize.width / imageAspect) - selfSize.height) / 2.0f);
        }
    } else {
    }
    imageRect = CGRectMake(-offsetX, -offsetY, selfSize.width + (offsetX * 2), selfSize.height + (offsetY * 2));
  }
  else {
    imageRect = CGRectMake(0, 0, selfSize.width, selfSize.height);
  }

  if (image == nil) {
    return;
  }
  [image drawInRect:imageRect];
}

- (UIImage *) drawImage
{
  if (path != nil) {
    [path strokeWithBlendMode:kCGBlendModeClear alpha:0];
  }
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  [self setImage:newImage];
  return newImage;
}

-(void) drawImageEnd {
  if (image == nil) {
    return;
  }
  imageTakenFromView = YES;
  image = [self drawImage];
  UIGraphicsEndImageContext();
  path = nil;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self reportTouchState:true];
  UITouch *touch = [touches anyObject];
  path = [UIBezierPath bezierPath];
  path.lineWidth = brushSize;
  path.lineCapStyle = kCGLineCapRound;
  path.lineJoinStyle = kCGLineJoinRound;

  CGPoint point = [touch locationInView:self];
  [path moveToPoint:point];
  [self updateGrid:point]; // Update grid immediately on touch start
  [self drawImageStart];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint point = [touch locationInView:self];

  // Validate point is within bounds
  if (point.x < 0 || point.y < 0 || point.x > self.bounds.size.width || point.y > self.bounds.size.height) {
    return;
  }

  [path addLineToPoint:point];
  [self updateGrid: point];
  if (!cleared && scratchProgress > threshold) {
    cleared = true;
    [self reportScratchState];
  }
  [self drawImage];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (path == nil)
  {
    return;
  }
  [self reportTouchState:false];
  [self drawImageEnd];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  if (path == nil)
  {
    return;
  }
  [self reportTouchState:false];
  [self drawImageEnd];
}

-(void) reportImageLoadFinished:(BOOL)success {
  [self._delegate onImageLoadFinished:self successState:success];
}

-(void) reportTouchState:(BOOL)state {
  [self._delegate onTouchStateChanged:self touchState:state];
}

-(void) reportScratchProgress
{
  [self._delegate onScratchProgressChanged:self didChangeProgress:scratchProgress];
}

-(void) reportScratchState {
  [self._delegate onScratchDone:self isScratchDone:cleared];
}

@end
