//
//  ViewController.m
//  FilterOfSplitScreen
//
//  Created by China on 2020/8/9.
//  Copyright © 2020 China. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import "FilterBar.h"
#import <Masonry/Masonry.h>

typedef struct {
    GLKVector3 positionCoord;//(x,y,z)
    GLKVector2 textureCoord;//(s,t)
} SenceVertex;

#define SCREENWIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREENHEIGHT [[UIScreen mainScreen] bounds].size.height
#define RECTSTATUS [[UIApplication sharedApplication] statusBarFrame]
#define BOTTOM_SAFE_HEIGHT (RECTSTATUS.size.height == 44 ? 34 : 0)
#define FILTERBARHEIGHT 100.0

@interface ViewController ()<FilterBarDelegate>
@property (nonatomic, assign) SenceVertex * vertexs;
@property (nonatomic, strong) EAGLContext * context;
//刷新屏幕
@property (nonatomic, strong) CADisplayLink * displayLink;
//开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
//着色器程序
@property (nonatomic, assign) GLuint program;
//顶点缓冲区
@property (nonatomic, assign) GLuint vertextBuffer;
//纹理ID
@property (nonatomic, assign) GLuint textureID;

@property (nonatomic, strong) NSArray * dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareForView];
    [self prepareForData];
    [self prepareForAction];
}
- (void)prepareForData{
    _dataSource = @[@"原图", @"二分屏", @"三分屏", @"四分屏", @"六分屏", @"九分屏"];
    
}
- (void)prepareForView{
    self.view.backgroundColor = [UIColor blackColor];
    [self setUpFilterBar];
    [self filterInit];
}
- (void)prepareForAction{
    
}
- (void)filterInit{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    // 开辟顶点数组内存空间
    self.vertexs = malloc(sizeof(SenceVertex) * 4);
    
    //顶点及纹理数据填入
    self.vertexs[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertexs[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertexs[2] = (SenceVertex){{1, -1, 0}, {1, 0}};
    self.vertexs[3] = (SenceVertex){{1, 1, 0}, {1, 1}};
    
    //创建Layer
    CAEAGLLayer * layer = [[CAEAGLLayer alloc] init];
    
    //设置图层Frame
    layer.frame = CGRectMake(0, RECTSTATUS.size.height + 44, SCREENWIDTH, SCREENHEIGHT - BOTTOM_SAFE_HEIGHT - FILTERBARHEIGHT - RECTSTATUS.size.height - 44);
    
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    [self.view.layer addSublayer:layer];
    
    [self bindRenderLayer:layer];
    
    //图片路径
    NSString * imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"liqin.png"];
    
    //读取图片
    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
    // 将图片转换成纹理图片
    GLuint textureID = [self creatTextureWithImage:image];
    
    //绑定纹理ID
    self.textureID = textureID;
    
    // 设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
}

//绑定渲染缓冲区
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer{
    // 创建渲染缓冲区，帧缓冲对象
    GLuint renderBuffer, frameBuffer;
    
    //获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    //获取帧缓存区名称,绑定帧缓存区以及将渲染缓存区附着到帧缓存区上
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

- (GLuint)creatTextureWithImage:(UIImage *)image{
    //将图片转换成CGImageRef
    CGImageRef imageRef = [image CGImage];
    //判断图片是否获取成功
    if (!imageRef) {
        NSLog(@"Faild to Load Image");
        return 0;
    }
    
    //读取图片属性
    GLuint width = (GLuint)CGImageGetWidth(imageRef);
    GLuint height = (GLuint)CGImageGetHeight(imageRef);
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    //图片颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //图片字节数
    void *imageData = malloc(width * height * 4);
    
    //创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 将图片翻转过来
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, imageRect);
    
    // 对图片进行重新绘制 得到解压后的位图
    CGContextDrawImage(context, imageRect, imageRef);
    
    //设置图片纹理属性
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    //设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //绑定纹理
    /*
    参数1：纹理维度
    参数2：纹理ID,因为只有一个纹理，给0就可以了。
    */
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    //释放空间
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}



#pragma mark — FilterBar
- (void)setUpFilterBar{
    FilterBar * filterBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH, FILTERBARHEIGHT)];
    filterBar.delegate = self;
    filterBar.itemList = _dataSource;
    [self.view addSubview:filterBar];
    [filterBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(FILTERBARHEIGHT));
        make.bottom.equalTo(self.view).with.offset(-BOTTOM_SAFE_HEIGHT);
    }];
    
}
#pragma mark — FilterBarDelegate



//获取渲染缓存区的宽
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}
//获取渲染缓存区的高
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}
@end
