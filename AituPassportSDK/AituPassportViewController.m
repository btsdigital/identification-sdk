//
//  AituPassportViewController.m
//  PassportRTCCordovaPlugin
//
//  Created by BTSD on 10/20/20.
//

#import "AituPassportViewController.h"
#import "AituNavigationDelegateProxy.h"

@interface AituPassportViewController ()

@property (nonatomic) AituNavigationDelegateProxy *delegateProxy;

@end

@implementation AituPassportViewController {
    NSTimer *timer;
    NSString *hostUrl;
}

- (WKWebView *)wkWebView {
    return (WKWebView *)self.webView;
}

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.startPage = @"";
        self.redirectURL = @"";
    }
    return self;
}

- (instancetype)initWithUrl:(NSString * _Nonnull)url
                redirectUrl:(NSString *_Nonnull)redirectUrl
                    options:(AituPassportOptions *_Nullable)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.startPage = url;
        self.redirectURL = redirectUrl;
        self.options = options;
    }
    return self;
}

- (void)setDelegate:(id<AituPassportViewControllerDelegate>)delegate {
    _delegate = delegate;
    self.delegateProxy.supplementary = delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id originalDelegate = self.wkWebView.navigationDelegate;
    self.delegateProxy = [[AituNavigationDelegateProxy alloc] initWithOriginal:originalDelegate];
    self.delegateProxy.supplementary = self.delegate;
    self.wkWebView.navigationDelegate = self.delegateProxy;
    hostUrl = self.wkWebView.URL.host;
    [[NSUserDefaults standardUserDefaults] setValue:self.options.language forKey:@"did-language"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"is-aitu-passport-sdk"];
    
    [self evaluateSetIsSDK];
    [self setBackButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    timer = [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(tiktak)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [timer invalidate];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    [self setUIDocumentMenuViewControllerSoureViewsIfNeeded:viewControllerToPresent];
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)setUIDocumentMenuViewControllerSoureViewsIfNeeded:(UIViewController *)viewControllerToPresent {
    if (@available(iOS 13, *)) {
        if ([viewControllerToPresent isKindOfClass:[UIDocumentMenuViewController class]]
            && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            viewControllerToPresent.popoverPresentationController.sourceView = self.wkWebView;
            viewControllerToPresent.popoverPresentationController.sourceRect = CGRectMake(self.wkWebView.center.x, self.wkWebView.center.y, 1, 1);
        }
    }
}

- (void)tiktak {
    if (self.webView.backgroundColor == UIColor.clearColor) {
        self.webView.backgroundColor = UIColor.whiteColor;
    }
    [self setBackButtonColor];
    [self toggleIsAituPassportSDK];
    NSString *urlString = self.wkWebView.URL.absoluteString;
    if ([urlString containsString:self.redirectURL] && ![urlString containsString:@"redirect_uri"]) {
        [timer invalidate];
        [self.delegate passportViewController:self didTriggerRedirectUrl:urlString];
    }
}

- (void)setBackButton {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"←" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    [self.navigationItem setLeftBarButtonItem:backButton animated:YES];
    [self setBackButtonColor];
}

- (void)setBackButtonColor {
    if ([self needBackButton]) {
        [self.navigationItem.leftBarButtonItem setTintColor:UIColor.systemBlueColor];
    } else {
        [self.navigationItem.leftBarButtonItem setTintColor:UIColor.clearColor];
    }
}

- (void)goBack {
    if (self.wkWebView.canGoBack) {
        [self setBackButtonColor];
        [self.wkWebView goBack];
    }
}

- (Boolean)needBackButton {
    if (self.wkWebView.canGoBack && (![self.wkWebView.URL.host isEqualToString:hostUrl] || [self.wkWebView.URL.absoluteString containsString:@"user-agreement"] || [self.wkWebView.URL.absoluteString containsString:@"privacy-policy"])) {
        return true;
    }
    return false;
}

- (void)toggleIsAituPassportSDK {
    if ([self.wkWebView.URL.host isEqualToString:hostUrl]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"is-aitu-passport-sdk"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"is-aitu-passport-sdk"];
    }
}

- (void)evaluateSetIsSDK {
    NSString *script = @"window.isAituPassportSDK = true;";
    [self.wkWebView evaluateJavaScript:script completionHandler:nil];
}

- (void)dealloc {
    [timer invalidate];
}

@end
