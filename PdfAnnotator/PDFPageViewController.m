//
//  PDFPageViewController.m
//  PdfAnnotator
//
//  Created by Raphael Cruzeiro on 7/2/11.
//  Copyright 2011 Inspira Tecnologia e Mkt. All rights reserved.
//

#import "PDFPageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PDFDocument.h"
#import "DrawingViewController.h"

@implementation PDFPageViewController

@synthesize _document;
@synthesize pagingViewController;
@synthesize drawingViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadDocument:(PDFDocument *)document
{
    self._document = document;
    [self refreshPage];
}

- (void)refreshPage
{  
    if(contentView) {
        [pagingViewController.view retain]; 
        
        for(UIView *v in self.view.subviews) {
            [v removeFromSuperview];
            [v release];
        }
    }
    
    if(drawingViewController) {
        [drawingViewController release];
    }
    
    if(!pagingViewController) {
        pagingViewController = [[PDFPagingViewController alloc] initWithDocument:self._document AndObserver:self];
    }
    
    CGRect pageRect = CGRectIntegral(CGPDFPageGetBoxRect(self._document.page, kCGPDFCropBox));
    
    pageRect.origin.x = 0;
    pageRect.origin.y = 0;
    
    self.drawingViewController = [[DrawingViewController alloc] initWithFrame:pageRect];
    
    pageRect.origin.x = 1;
    pageRect.origin.y = 1;

    CATiledLayer *tiledLayer = [CATiledLayer layer];
    tiledLayer.delegate = self;
    tiledLayer.tileSize = CGSizeMake(1024.0, 1024.0);
    tiledLayer.levelsOfDetail = 1000;
    tiledLayer.levelsOfDetailBias = 1000;
    tiledLayer.frame = pageRect;
    
    pageRect.origin.x = 0;
    
    pageRect.origin.y = 30;
    pageRect.origin.x = ((self.view.frame.size.width / 2) - ((pageRect.size.width + 2) / 2));
    
    pageRect.size.width += 2;
    pageRect.size.height += 2;
    
    contentView = [[UIView alloc] initWithFrame:pageRect];
    [contentView.layer addSublayer:tiledLayer];
    
    [contentView addSubview:self.drawingViewController.view];
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin = CGPointZero;
    
    scrollView = [[UIScrollView alloc] initWithFrame:viewFrame];
    
    [contentView setBackgroundColor:[UIColor darkGrayColor]];
    
    scrollView.delegate = self;
    scrollView.contentSize = pageRect.size;
    scrollView.maximumZoomScale = 1000;
    [scrollView setMaximumZoomScale:4];
    [scrollView addSubview:contentView];
    
    [self.view addSubview:scrollView];   
    [self.view addSubview:pagingViewController.view];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return contentView;
}

- (void)pageSelected:(NSInteger)page
{
    [self._document loadPage:page];
    [self refreshPage];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if(self._document) {
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
        CGContextTranslateCTM(ctx, 0.0, layer.bounds.size.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(self._document.page, kCGPDFCropBox, layer.bounds, 0, true));
        CGContextDrawPDFPage(ctx, self._document.page);
    }
}

- (void)setPenMode:(BOOL)enabled
{
    [scrollView setScrollEnabled:!enabled];
    [drawingViewController setDrawable:enabled];
}

- (void)setHandMode:(BOOL)enabled
{
    [scrollView setScrollEnabled:enabled];
    [drawingViewController setDrawable:!enabled];
}

- (void)setBrush:(TextMarkerBrush)brush
{
    [drawingViewController setBrush:brush];
}

- (void)dealloc
{
    [pagingViewController release];
    
    [super dealloc];
}

@end
