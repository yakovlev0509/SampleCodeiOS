//
//  StoreBaseViewController.m
//  BookFusion
//
//  Created by Developer on 7/7/16.
//  Copyright © 2016 Developer. All rights reserved.
//

#import "StoreBaseViewController.h"
#import "BookCollectionViewCell.h"
#import "SearchCollectionReusableView.h"
#import "StoreEmptyDataView.h"
#import "StoreBookDetailsViewController.h"
#import "CustomInfiniteIndicator.h"
#import "CategoryPanelViewController.h"
#import "OrdersView.h"


/* Cells ID */
static NSString * const BOOK_CELL_ID = @"BookCell";

/* Default values */
//static NSUInteger const LANDSCAPE_HORIZONOTAL_CELL_COUNT_IPAD   = 6;
//static NSUInteger const POIRTRAIT_HORIZONOTAL_CELL_COUNT_IPAD   = 3;
//static NSUInteger const HORIZONOTAL_CELL_COUNT_IPHONE           = 2;



@interface StoreBaseViewController () <UICollectionViewDataSource, UICollectionViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

// Panel
@property (strong, nonatomic) CategoryPanelViewController   *categoryPanel;
@property (weak, nonatomic) IBOutlet UIView                 *categoryPanelView;

/* UI Elements */
@property (weak, nonatomic) IBOutlet UIView                 *searchPanel;
@property (weak, nonatomic) IBOutlet SearchView             *searchView;
@property (weak, nonatomic) IBOutlet OrdersView             *ordersView;
@property (weak, nonatomic) IBOutlet UICollectionView       *collectionView;

/* UI Layouts */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ordersViewTopPosition;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewTopPosition;

/* Data */
@property (nonatomic, strong) NSMutableArray    *content;
@property (nonatomic, assign) BOOL              showOrdersView;
@property (nonatomic, assign) BOOL              showSearchView;
@property (nonatomic, strong) StoreBook         *selectedBook;

/* Order */
@property (nonatomic, assign) OrderType     orderType;
@property (nonatomic, assign) OrderStatus   orderStatus;

/* Filters */
@property (nonatomic, assign) LanguageFilter    languageFilter;
@property (nonatomic, assign) BookPriceFilter   bookPriceFilter;
@property (nonatomic, strong) NSString          *categoryFilter;


@end



@implementation StoreBaseViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setup];
    [self setupSearchView];
    [self setupOrdersView];
    [self setupCategoryPanel];
}

- (void)viewWillAppear:(BOOL)animated {
 
    [super viewWillAppear:animated];
    [self updateCollectionViewLayoutWithSize:self.collectionView.bounds.size];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self updateCollectionViewLayoutWithSize:size];
}

- (void)updateCollectionViewLayoutWithSize:(CGSize)size {
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    
    if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
        layout.itemSize = [self getCurrentCellSizeForCellsCount:HORIZONOTAL_CELL_COUNT_IPHONE];
    else {
        if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
            layout.itemSize = [self getCurrentCellSizeForCellsCount:LANDSCAPE_HORIZONOTAL_CELL_COUNT_IPAD];
        else
            layout.itemSize = [self getCurrentCellSizeForCellsCount:POIRTRAIT_HORIZONOTAL_CELL_COUNT_IPAD];
    }
    
    [layout invalidateLayout];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"StoreBookDetails"]) {
        
        StoreBookDetailsViewController *detailsViewController = segue.destinationViewController;
        [detailsViewController setupDetailsForBook:self.selectedBook];
    }
    else if ([segue.identifier isEqualToString:@"ShowCategoryPanelViewController"]) {
        
        UINavigationController *navigationViewController = segue.destinationViewController;
        
        self.categoryPanel = [[navigationViewController viewControllers] objectAtIndex:0];
    }
}

#pragma mark - Public

- (void)updateContent {
    
    if (![RequestManager defaultManager].connection) {
        
        [self.content removeAllObjects];
        [self.collectionView reloadData];
    }
    else if (!self.content || (self.content && ![self.content count]))
        [self getAllBooksWithCompletionBlock:^(NSArray *books, NSError *error) {
            
            self.content = [books mutableCopy];
            [self.collectionView reloadData];
        }];
}

#pragma mark - Private

- (void)setup {
    
    [self.collectionView setKeyboardAvoidingEnabled:YES];
    [self.collectionView registerNib:[UINib nibWithNibName:@"BookCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:BOOK_CELL_ID];
    [self.collectionView registerNib:[UINib nibWithNibName:@"SearchCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SearchView"];
    
    
    // Setup placeholder for empty bookshelf
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
    
    // Next content page
    CustomInfiniteIndicator *infiniteIndicator = [[CustomInfiniteIndicator alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    infiniteIndicator.innerColor = [UIManager color1];
    self.collectionView.infiniteScrollIndicatorView = infiniteIndicator;
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView addInfiniteScrollWithHandler:^(UICollectionView* collectionView) {
        
        [weakSelf getAllBooksWithCompletionBlock:^(NSArray *books, NSError *error) {
            
            NSMutableArray *indexPaths = [NSMutableArray new];
            NSInteger index = weakSelf.content.count;
            

            for (BFBook *book in books) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index++ inSection:0];
                
                [weakSelf.content addObject:book];
                [indexPaths addObject:indexPath];
            }
            
            
            [collectionView performBatchUpdates:^{

                [collectionView insertItemsAtIndexPaths:indexPaths];
            } completion:^(BOOL finished) {

                [collectionView finishInfiniteScroll];
            }];
        }];
    }];
    
    [self.collectionView setShouldShowInfiniteScrollHandler:^BOOL(UIScrollView *scrollView) {

        return YES;
    }];
}

- (void)setupSearchView {
    
    __weak typeof(self) weakSelf = self;
    
    self.searchView.didEndSearch = ^(NSString *searchText) {
        
        weakSelf.content = nil;
        [weakSelf.collectionView reloadData];
        [weakSelf getAllBooksWithCompletionBlock:^(NSArray *books, NSError *error) {
            
            weakSelf.content = [books mutableCopy];
            [weakSelf.collectionView reloadData];
        }];
    };
}

- (void)setupOrdersView {
    
    __weak typeof(self) weakSelf = self;
    
    self.ordersView.controller = self;
    
    void (^reloadContent)(void) = ^() {
        
        [weakSelf.content removeAllObjects];
        [weakSelf.collectionView reloadData];
        
        [weakSelf getAllBooksWithCompletionBlock:^(NSArray *books, NSError *error) {
            
            weakSelf.content = [books mutableCopy];
            [weakSelf.collectionView reloadData];
        }];
    };
    
    self.ordersView.didSelectOrder = ^(OrderType orderType, OrderStatus orderStatus) {
        
        weakSelf.orderType = orderType;
        weakSelf.orderStatus = orderStatus;
        
        reloadContent();
    };
    
    // Select language filter
    self.ordersView.didSelectLanguageFilter = ^(LanguageFilter languageFilter) {
        
        weakSelf.languageFilter = languageFilter;
        
        reloadContent();
    };
    
    // Select book price filter
    self.ordersView.didSelectBookPriceFilter = ^(BookPriceFilter bookPricaFilter) {
        
        // Setup category panel
        if (!weakSelf.categoryFilter)
            [weakSelf.categoryPanel setupBookPriceFilter:bookPricaFilter];
        
        weakSelf.bookPriceFilter = bookPricaFilter;
        
        reloadContent();
    };
}

- (void)setupCategoryPanel {
    
    __weak typeof(self) weakSelf = self;
    
    void (^reloadContent)(void) = ^() {
        
        [weakSelf.content removeAllObjects];
        [weakSelf.collectionView reloadData];
        
        [weakSelf getAllBooksWithCompletionBlock:^(NSArray *books, NSError *error) {
            
            weakSelf.content = [books mutableCopy];
            [weakSelf.collectionView reloadData];
        }];
    };
    
    self.categoryPanel.didSelectCategoryName = ^(NSString *category, BookPriceFilter bookPriceFilter) {
        
        [weakSelf.ordersView setupUIBookPriceType:bookPriceFilter];
        
        weakSelf.bookPriceFilter = bookPriceFilter;
        weakSelf.categoryFilter = category;
        reloadContent();
        
        
        [weakSelf.categoryPanel hideCategoriesPopupWithCompletion:^{
            
            weakSelf.categoryPanelView.hidden = YES;
        }];
    };
    
    self.categoryPanel.cancelDidAction = ^() {
        
        weakSelf.categoryPanelView.hidden = YES;
    };
}

- (NSUInteger)getPage {
    
    double page = (double)[self.content count] / (double)50;
    return (ceil(page) + 1);
}

- (void)getAllBooksWithCompletionBlock:(void (^)(NSArray *books, NSError *error))block {
    
    if (self.showSearchView)
        [[RequestManager defaultManager] getStoreBooks:self.searchView.searchText page:[self getPage] category:self.categoryFilter orderType:self.orderType orderStatus:self.orderStatus languageFilter:self.languageFilter bookPriceFilter:self.bookPriceFilter withCompletionBlock:^(NSArray *books, NSError *error) {
            
            if (block)
                block(books, error);
        }];
    else
        [[RequestManager defaultManager] getStoreBooks:@"" page:[self getPage] category:self.categoryFilter orderType:self.orderType orderStatus:self.orderStatus languageFilter:self.languageFilter bookPriceFilter:self.bookPriceFilter withCompletionBlock:^(NSArray *books, NSError *error) {
            
            if (block)
                block(books, error);
        }];
}

- (CGSize)getCurrentCellSizeForCellsCount:(NSUInteger)count {
    
    NSUInteger horizontalCellsCount = count;
    
    NSUInteger cellWidht = (self.collectionView.bounds.size.width - 24) / horizontalCellsCount;
    
    return CGSizeMake(cellWidht, cellWidht * 1.74);
}

- (void)goToSettings {
    
    // Show settings popup
    
    [[NavigationManager defaultManager] showUpgradeAccountPopupFor:self
                                                      goToSettings:^ {
                                                          
                                                          [[NavigationManager defaultManager] openUpdateAccountSettings];
                                                      }
                                                            cancel:nil];
}

#pragma mark - UICollectionViewDataSource


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [self.content count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    StoreBook *book = [self.content objectAtIndex:indexPath.row];
    
    BookCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:BOOK_CELL_ID forIndexPath:indexPath];
    
    [cell setupCellForStoreBook:book
                      withStyle:StoreBookStyleDefaultCell];
    [cell setupCellStatus:LoadingStatusDone];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
        return [self getCurrentCellSizeForCellsCount:HORIZONOTAL_CELL_COUNT_IPHONE];
    else {
        if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
            return [self getCurrentCellSizeForCellsCount:LANDSCAPE_HORIZONOTAL_CELL_COUNT_IPAD];
        else
            return [self getCurrentCellSizeForCellsCount:POIRTRAIT_HORIZONOTAL_CELL_COUNT_IPAD];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    return UIEdgeInsetsMake(6, 12, 6, 12);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return 0;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[BookCollectionViewCell class]])
        [((BookCollectionViewCell *) cell) closeOperations];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    StoreBook *currentBook = [self.content objectAtIndex:indexPath.row];
    
    if (IS_IPhone) {
        
        self.selectedBook = currentBook;
        [self performSegueWithIdentifier:@"StoreBookDetails" sender:self];
    }
    else {

        __weak typeof(self) weakSelf = self;
        
        // Show book details popup
        [[NavigationManager defaultManager] showStoreBookDetailsPopupFor:self
                                                                    book:currentBook
                                                             fromLibrary:nil
                                                            addToLibrary:^{
                                                                
                                                                [weakSelf goToSettings];
                                                            }
                                                                  cancel:nil];
    }
}

#pragma mark - DZNEmptyDataSetDelegate

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"StoreEmptyDataView"
                                                         owner:nil
                                                       options:nil];
    
    StoreEmptyDataView *view = nibContents[0];
    
    if (self.view.bounds.size.width <= view.bounds.size.width)
        view.frame = CGRectMake(0, 0, scrollView.bounds.size.width, scrollView.bounds.size.height);
    
    return view;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    
    if (![RequestManager defaultManager].connection)
        return YES;
    else
        return NO;
}

#pragma mark - Actions

- (IBAction)categoryPanelAction:(id)sender {
    
    if (self.categoryPanelView.hidden) {
        
        self.categoryPanelView.hidden = NO;
        [self.categoryPanel showCategoriesPopup];
    }
    else {
        
        __weak typeof(self) weakSelf = self;
        
        [self.categoryPanel hideCategoriesPopupWithCompletion:^{
            
            weakSelf.categoryPanelView.hidden = YES;
        }];
    }
}

- (IBAction)searchAction:(id)sender {
    
    if (![RequestManager defaultManager].connection && (!self.content || ![self.content count]))
        return;
    
    if (!self.showSearchView)
        self.searchViewTopPosition.constant = 0;
    else
        self.searchViewTopPosition.constant = - self.searchPanel.bounds.size.height;
    
    [self.searchPanel setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
    
    
    self.showSearchView = !self.showSearchView;
}

- (IBAction)orderViewAction:(id)sender {
    
    if (![RequestManager defaultManager].connection  && (!self.content || ![self.content count]))
        return;
    
    if (!self.showOrdersView)
        self.ordersViewTopPosition.constant = 0;
    else
        self.ordersViewTopPosition.constant = - self.ordersView.bounds.size.height;
    
    [self.ordersView setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
    
    
    self.showOrdersView = !self.showOrdersView;
}

@end
