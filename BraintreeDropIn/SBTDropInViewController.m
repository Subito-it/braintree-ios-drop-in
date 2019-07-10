// Copyright © 2019 Subito.it. All rights reserved.

#import "SBTDropInViewController.h"

#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

#if __has_include("BraintreeCard.h")
#import "BraintreeCard.h"
#import "BraintreeUnionPay.h"
#else
#import <BraintreeCard/BraintreeCard.h>
#import <BraintreeUnionPay/BraintreeUnionPay.h>
#endif

#import "BTAPIClient_Internal_Category.h"

#import "BTCardFormViewController.h"
#import "BTVaultManagementViewController.h"
#import "BTEnrollmentVerificationViewController.h"

@interface SBTDropInViewController () <BTPaymentSelectionViewControllerDelegate, BTDropInControllerDelegate, BTAppSwitchDelegate, BTViewControllerPresentingDelegate>

@property (nonatomic, copy) NSArray *displayCardTypes;
@property (nonatomic, copy) BTDropInControllerHandler handler;

@property (nonatomic, strong) BTAPIClient *apiClient;
@property (nonatomic, strong) BTConfiguration *configuration;
@property (nonatomic, strong) BTDropInRequest *dropInRequest;
@property (nonatomic, strong) BTPaymentSelectionViewController *paymentSelectionViewController;

@end

@implementation SBTDropInViewController

- (nullable instancetype)initWithAuthorization:(NSString *)authorization request:(BTDropInRequest *)request handler:(BTDropInControllerHandler) handler {
    if (self = [super init]) {
        BTAPIClient *client = [[BTAPIClient alloc] initWithAuthorization:authorization sendAnalyticsEvent:NO];
        
        self.apiClient = [client copyWithSource:client.metadata.source integration:BTClientMetadataIntegrationDropIn2];
        self.displayCardTypes = @[];
        self.handler = handler;
        
        _dropInRequest = [request copy];
        
        if (!_apiClient || !_dropInRequest) {
            return nil;
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.paymentSelectionViewController = [[BTPaymentSelectionViewController alloc] initWithAPIClient:self.apiClient request:self.dropInRequest];
    
    [self addChildViewController:self.paymentSelectionViewController];
    [self.view addSubview:self.paymentSelectionViewController.view];
    [self.paymentSelectionViewController didMoveToParentViewController:self];
    
    self.paymentSelectionViewController.delegate = self;
    self.paymentSelectionViewController.navigationItem.leftBarButtonItem.target = self;
    self.paymentSelectionViewController.navigationItem.leftBarButtonItem.action = @selector(cancelHit:);
    self.paymentSelectionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
     [self.paymentSelectionViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
     [self.paymentSelectionViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
     [self.paymentSelectionViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
     [self.paymentSelectionViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.apiClient sendAnalyticsEvent:@"ios.dropin2.appear"];
    
    if (!self.isBeingPresented) {
        return;
    }
    
    self.configuration = nil;
    self.paymentSelectionViewController.view.alpha = 1.0;
    [self.paymentSelectionViewController loadConfiguration];
    
    __weak typeof(self) weakSelf = self;
    [self.apiClient fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf didFetchOrReturnRemoveConfiguration:configuration error:error];
        });
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.apiClient sendAnalyticsEvent:@"ios.dropin2.disappear"];
}

- (void)didFetchOrReturnRemoveConfiguration:(BTConfiguration *)configuration error:(NSError *)error {
    if (error) {
        return self.handler(self, nil, error);
    }
    
    NSArray *supportedCardTypes = [configuration.json[@"creditCards"][@"supportedCardTypes"] asArray];
    NSMutableArray *paymentOptionTypes = [NSMutableArray new];
    
    for (NSString *supportedCardType in supportedCardTypes) {
        BTUIKPaymentOptionType paymentOptionType = [BTUIKViewUtil paymentOptionTypeForPaymentInfoType:supportedCardType];
        if (paymentOptionType != BTUIKPaymentOptionTypeUnknown) {
            [paymentOptionTypes addObject: @(paymentOptionType)];
        }
    }
    
    self.configuration = configuration;
    self.displayCardTypes = paymentOptionTypes;
    self.paymentSelectionViewController.view.alpha = 1.0;
}

- (void)cancelHit:(__unused id)sender {
    self.handler(self, [self cancelledResult], nil);
}

- (void)showCardForm:(__unused id)sender {
    BTCardFormViewController* formViewController = [[BTCardFormViewController alloc] initWithAPIClient:self.apiClient request:self.dropInRequest];
    formViewController.supportedCardTypes = self.displayCardTypes;
    formViewController.delegate = self;
    
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:formViewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)editPaymentMethods:(id)sender {
    BTVaultManagementViewController* vaultManagementViewController = [[BTVaultManagementViewController alloc] initWithAPIClient:self.apiClient request:self.dropInRequest];
    vaultManagementViewController.delegate = self;
    
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:vaultManagementViewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)reloadDropInData {
    [self.paymentSelectionViewController loadConfiguration];
}

- (void)paymentDriver:(id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectionCompletedWithPaymentMethodType:(BTUIKPaymentOptionType)type nonce:(BTPaymentMethodNonce *)nonce error:(NSError *)error {
    if (error != nil) {
        return self.handler(self, nil, error);
    }
    
    BTDropInResult *result = [[BTDropInResult alloc] init];
    result.paymentOptionType = type;
    result.paymentMethod = nonce;
    self.handler(self, result, error);
    
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:@"BT_dropInLastSelectedPaymentMethodType"];
}

- (void)cardTokenizationCompleted:(BTPaymentMethodNonce *)tokenizedCard error:(NSError *)error sender:(BTCardFormViewController *)sender {
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [sender dismissViewControllerAnimated:YES completion:^{
            if (tokenizedCard != nil) {
                BTDropInResult *result = [[BTDropInResult alloc] init];
                result.paymentMethod = tokenizedCard;
                result.paymentOptionType = [BTUIKViewUtil paymentOptionTypeForPaymentInfoType:tokenizedCard.type];
                weakSelf.handler(weakSelf, result, error);
            } else if (error == nil) {
                weakSelf.handler(weakSelf, [weakSelf cancelledResult], error);
            }
        }];
    });
}

- (void)sheetHeightDidChange:(__unused id)sender {
    // No action
}

- (void)appSwitcherWillPerformAppSwitch:(__unused id)appSwitcher {
    // No action
}

- (void)appSwitcherWillProcessPaymentInfo:(__unused id)appSwitcher {
    // No action
}

- (void)appSwitcher:(__unused id)appSwitcher didPerformSwitchToTarget:(__unused BTAppSwitchTarget)target {
    // No action
}

- (BTDropInResult *)cancelledResult {
    BTDropInResult *result = [[BTDropInResult alloc] init];
    result.cancelled = YES;
    return result;
}

@end
