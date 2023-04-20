/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDDiskCache.h"
#import "SDImageCacheConfig.h"
#import "SDFileAttributeHelper.h"
#import <CommonCrypto/CommonDigest.h>

#import "SDImageCache.h"

static const NSString *kRemainingDiskAge = @"remainingDiskAge";
static NSString * const SDDiskCacheExtendedAttributeName = @"com.hackemist.SDDiskCache";
NSString *_Nonnull const SDDiskCacheExtendedKeyDiskAge = @"com.hackemist.SDDiskCache.DiskAge";

typedef NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> SDDiskCacheCachedFiles;


@implementation SDDiskCacheConfigInfo

- (instancetype)initWithMaxDiskAge:(NSTimeInterval)maxDiskAge
                     diskCachePath:(NSString *)diskCachePath
               diskCacheExpireType:(SDImageCacheConfigExpireType)diskCacheExpireType {
    self = [super init];
    if (self) {
        _maxDiskAge = maxDiskAge;
        _diskCachePath = [diskCachePath stringByAbbreviatingWithTildeInPath].copy;
        _diskCacheExpireType = diskCacheExpireType;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.maxDiskAge = [coder decodeDoubleForKey:NSStringFromSelector(@selector(maxDiskAge))];
        self.diskCachePath = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(diskCachePath))];
        self.diskCacheExpireType = [coder decodeIntegerForKey:NSStringFromSelector(@selector(diskCacheExpireType))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeDouble:self.maxDiskAge forKey:NSStringFromSelector(@selector(maxDiskAge))];
    [coder encodeObject:self.diskCachePath forKey:NSStringFromSelector(@selector(diskCachePath))];
    [coder encodeInteger:self.diskCacheExpireType forKey:NSStringFromSelector(@selector(diskCacheExpireType))];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSUInteger)hash {
    return self.diskCachePath.hash;
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[SDDiskCacheConfigInfo class]]) {
        return NO;
    }
    SDDiskCacheConfigInfo *other = (SDDiskCacheConfigInfo *)object;
    return [other.diskCachePath isEqualToString:self.diskCachePath];
}

@end


@interface SDDiskCache ()

@property (nonatomic, copy) NSString *diskCachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;

@end

@implementation SDDiskCache

- (instancetype)init {
    NSAssert(NO, @"Use `initWithCachePath:` with the disk cache path");
    return nil;
}

#pragma mark - SDcachePathForKeyDiskCache Protocol
- (instancetype)initWithCachePath:(NSString *)cachePath config:(nonnull SDImageCacheConfig *)config {
    if (self = [super init]) {
        _diskCachePath = cachePath;
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    if (self.config.fileManager) {
        self.fileManager = self.config.fileManager;
    } else {
        self.fileManager = [NSFileManager new];
    }
}

- (BOOL)containsDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    
    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    if (!exists) {
        exists = [self.fileManager fileExistsAtPath:filePath.stringByDeletingPathExtension];
    }
    
    return exists;
}

- (NSData *)dataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        return data;
    }
    
    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    data = [NSData dataWithContentsOfFile:filePath.stringByDeletingPathExtension options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        return data;
    }
    
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    NSParameterAssert(data);
    NSParameterAssert(key);
    if (![self.fileManager fileExistsAtPath:self.diskCachePath]) {
        [self.fileManager createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    // transform to NSUrl
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
    
    [data writeToURL:fileURL options:self.config.diskCacheWritingOptions error:nil];
    
    // disable iCloud backup
    if (self.config.shouldDisableiCloud) {
        // ignore iCloud backup resource value error
        [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}

- (NSData *)extendedDataForKey:(NSString *)key {
    NSParameterAssert(key);
    
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    NSData *extendedData = [self extendedDataForPath:cachePathForKey];
    
    return extendedData;
}

- (void)setExtendedData:(NSData *)extendedData forKey:(NSString *)key {
    NSParameterAssert(key);
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    [self setExtendedData:extendedData forPath:cachePathForKey];
}

- (NSData *)extendedDataForPath:(NSString *)path {
    return [self.class extendedDataForPath:path];
}

+ (NSData *)extendedDataForPath:(NSString *)path {
    if (!path) {
        return nil;
    }
    NSData *extendedData = [SDFileAttributeHelper extendedAttribute:SDDiskCacheExtendedAttributeName atPath:path traverseLink:NO error:nil];
    return extendedData;
}

- (void)setExtendedData:(NSData *)extendedData forPath:(NSString *)path {
    [self.class setExtendedData:extendedData forPath:path];
}

+ (void)setExtendedData:(NSData *)extendedData forPath:(NSString *)path {
    if (!path) {
        return;
    }
    if (!extendedData) {
        // Remove
        [SDFileAttributeHelper removeExtendedAttribute:SDDiskCacheExtendedAttributeName atPath:path traverseLink:NO error:nil];
    } else {
        // Override
        [SDFileAttributeHelper setExtendedAttribute:SDDiskCacheExtendedAttributeName value:extendedData atPath:path traverseLink:NO overwrite:YES error:nil];
    }
}

- (id)extendedObjectForKey:(NSString *)key {
    NSParameterAssert(key);
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    return [self extendedObjectForPath:cachePathForKey];
}

- (void)setExtendedObject:(id)extendedObject forKey:(NSString *)key {
    NSParameterAssert(key);
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    [self setExtendedObject:extendedObject forPath:cachePathForKey];
}

- (id)extendedObjectForPath:(NSString *)path {
    return [self.class extendedObjectForPath:path];
}

+ (id)extendedObjectForPath:(NSString *)path {
    NSData *extendedData = [self extendedDataForPath:path];
    if (!extendedData) {
        return nil;
    }
    
    id extendedObject;
    if (@available(iOS 11, tvOS 11, macOS 10.13, watchOS 4, *)) {
        NSError *error;
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:extendedData error:&error];
        unarchiver.requiresSecureCoding = NO;
        extendedObject = [unarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
        if (error) {
            NSLog(@"NSKeyedUnarchiver unarchive failed with error: %@", error);
        }
    } else {
        @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            extendedObject = [NSKeyedUnarchiver unarchiveObjectWithData:extendedData];
#pragma clang diagnostic pop
        } @catch (NSException *exception) {
            NSLog(@"NSKeyedUnarchiver unarchive failed with exception: %@", exception);
        }
    }
    return extendedObject;
}

- (void)setExtendedObject:(id)extendedObject forPath:(NSString *)path {
    [self.class setExtendedObject:extendedObject forPath:path];
}

+ (void)setExtendedObject:(id)extendedObject forPath:(NSString *)path {
    if (!extendedObject || !path) {
        return;
    }
    
    NSData *extendedData;
    if (@available(iOS 11, tvOS 11, macOS 10.13, watchOS 4, *)) {
        NSError *error;
        extendedData = [NSKeyedArchiver archivedDataWithRootObject:extendedObject requiringSecureCoding:NO error:&error];
        if (error) {
            NSLog(@"NSKeyedArchiver archive failed with error: %@", error);
        }
    } else {
        @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            extendedData = [NSKeyedArchiver archivedDataWithRootObject:extendedObject];
#pragma clang diagnostic pop
        } @catch (NSException *exception) {
            NSLog(@"NSKeyedArchiver archive failed with exception: %@", exception);
        }
    }
    if (extendedData) {
        [self setExtendedData:extendedData forPath:path];
    }
}


- (void)removeDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    [self.fileManager removeItemAtPath:filePath error:nil];
}

- (void)removeDataForPath:(NSString *)path {
    [self.fileManager removeItemAtPath:path error:nil];
}

- (void)removeAllData {
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self.fileManager createDirectoryAtPath:self.diskCachePath
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:NULL];
}

- (void)removeExpiredData {
    SDDiskCacheCachedFiles *cacheFiles =
        [self.class removeExpiredAndCollectRemainingFilesInPath:self.diskCachePath
                                                withFileManager:self.fileManager
                                            diskCacheExpireType:self.config.diskCacheExpireType
                                                     maxDiskAge:self.config.maxDiskAge];
    
    [self.class removeCacheFiles:cacheFiles
                   toMaxDiskSize:self.config.maxDiskSize
                 withFileManager:self.fileManager];

}

+ (uint64_t)removeExpiredDataWithCacheConfigs:(NSArray<SDDiskCacheConfigInfo *> *)cacheConfigs {
    if (!cacheConfigs || ![cacheConfigs isKindOfClass:[NSArray class]] || cacheConfigs.count <= 0) {
        return 0;
    }

    NSUInteger maxDiskSize = SDImageCacheConfig.maxTotalDiskSize;
    if (maxDiskSize == 0) {
        return 0;
    }


    SDDiskCacheCachedFiles *totalCacheFiles = [NSMutableDictionary dictionary];    
    for (SDDiskCacheConfigInfo *cacheConfig in cacheConfigs) {
        SDDiskCacheCachedFiles *cacheFiles =
            [self removeExpiredAndCollectRemainingFilesInPath:[cacheConfig.diskCachePath stringByExpandingTildeInPath]
                                              withFileManager:NSFileManager.defaultManager
                                          diskCacheExpireType:cacheConfig.diskCacheExpireType
                                                   maxDiskAge:cacheConfig.maxDiskAge];
        
        [totalCacheFiles addEntriesFromDictionary:cacheFiles];
    }
    
    uint64_t size = [self removeCacheFiles:totalCacheFiles
                    toMaxDiskSize:maxDiskSize
                  withFileManager:NSFileManager.defaultManager];
    
     return size;
}

- (nullable NSString *)cachePathForKey:(NSString *)key {
    NSParameterAssert(key);
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

+ (NSUInteger)totalSizeOfPath:(NSString *)diskCachePath withFileManager:(NSFileManager *)fileManager {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary<NSString *, id> *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (NSUInteger)totalSize {
    return [self.class totalSizeOfPath:self.diskCachePath withFileManager:self.fileManager];
}

+ (uint64_t)totalSizeWithCacheConfigs:(NSArray<SDDiskCacheConfigInfo *> *)cacheConfigs {
    uint64_t size = 0;
    for (SDDiskCacheConfigInfo *cacheConfig in cacheConfigs) {
        size += [self totalSizeOfPath:[cacheConfig.diskCachePath stringByExpandingTildeInPath] withFileManager:[NSFileManager defaultManager]];
    }
    return size;
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    count = fileEnumerator.allObjects.count;
    return count;
}

#pragma mark - Cache paths

- (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path {
    NSString *filename = SDDiskCacheFileNameForKey(key);
    return [path stringByAppendingPathComponent:filename];
}

- (void)moveCacheDirectoryFromPath:(nonnull NSString *)srcPath toPath:(nonnull NSString *)dstPath {
    NSParameterAssert(srcPath);
    NSParameterAssert(dstPath);
    // Check if old path is equal to new path
    if ([srcPath isEqualToString:dstPath]) {
        return;
    }
    BOOL isDirectory;
    // Check if old path is directory
    if (![self.fileManager fileExistsAtPath:srcPath isDirectory:&isDirectory] || !isDirectory) {
        return;
    }
    // Check if new path is directory
    if (![self.fileManager fileExistsAtPath:dstPath isDirectory:&isDirectory] || !isDirectory) {
        if (!isDirectory) {
            // New path is not directory, remove file
            [self.fileManager removeItemAtPath:dstPath error:nil];
        }
        NSString *dstParentPath = [dstPath stringByDeletingLastPathComponent];
        // Creates any non-existent parent directories as part of creating the directory in path
        if (![self.fileManager fileExistsAtPath:dstParentPath]) {
            [self.fileManager createDirectoryAtPath:dstParentPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        // New directory does not exist, rename directory
        [self.fileManager moveItemAtPath:srcPath toPath:dstPath error:nil];
    } else {
        // New directory exist, merge the files
        NSDirectoryEnumerator *dirEnumerator = [self.fileManager enumeratorAtPath:srcPath];
        NSString *file;
        while ((file = [dirEnumerator nextObject])) {
            [self.fileManager moveItemAtPath:[srcPath stringByAppendingPathComponent:file] toPath:[dstPath stringByAppendingPathComponent:file] error:nil];
        }
        // Remove the old path
        [self.fileManager removeItemAtPath:srcPath error:nil];
    }
}

#pragma mark - Hash

#define SD_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline NSString * _Nonnull SDDiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > SD_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}
#pragma clang diagnostic pop

+ (SDDiskCacheCachedFiles *)removeExpiredAndCollectRemainingFilesInPath:(NSString *)diskCachePath
                                                        withFileManager:(NSFileManager *)fileManager
                                                    diskCacheExpireType:(SDImageCacheConfigExpireType)diskCacheExpireType
                                                             maxDiskAge:(NSTimeInterval)maxDiskCacheAge {
                 
    NSURL *diskCacheURL = [NSURL fileURLWithPath:diskCachePath isDirectory:YES];
    
    const NSString *kRemainingDiskAge = @"remainingDiskAge";
    // Compute content date key to be used for tests
    NSURLResourceKey cacheContentDateKey = NSURLContentModificationDateKey;
    switch (diskCacheExpireType) {
        case SDImageCacheConfigExpireTypeAccessDate:
            cacheContentDateKey = NSURLContentAccessDateKey;
            break;
        case SDImageCacheConfigExpireTypeModificationDate:
            cacheContentDateKey = NSURLContentModificationDateKey;
            break;
        case SDImageCacheConfigExpireTypeCreationDate:
            cacheContentDateKey = NSURLCreationDateKey;
            break;
        case SDImageCacheConfigExpireTypeChangeDate:
            cacheContentDateKey = NSURLAttributeModificationDateKey;
            break;
        default:
            break;
    }
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, cacheContentDateKey, NSURLTotalFileAllocatedSizeKey];
    
    // This enumerator prefetches useful properties for our cache files.
    NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheURL
                                              includingPropertiesForKeys:resourceKeys
                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                            errorHandler:NULL];
    
    SDDiskCacheCachedFiles *cacheFiles = [NSMutableDictionary dictionary];
        
    // Enumerate all of the files in the cache directory.  This loop has two purposes:
    //
    //  1. Removing files that are older than the expiration date.
    //  2. Storing file attributes for the size-based cleanup pass.
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    NSDate *now = [NSDate date];
    for (NSURL *fileURL in fileEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        
        // Skip directories and errors.
        if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        NSTimeInterval maxDiskAge = maxDiskCacheAge;
        id extendObject = [self extendedObjectForPath:fileURL.path];
        if ([extendObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *diskAge = ((NSDictionary *)extendObject)[SDDiskCacheExtendedKeyDiskAge];
            if (diskAge) {
                maxDiskAge = diskAge.doubleValue;
            }
        }
        
        if (maxDiskAge == 0) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
        
        NSTimeInterval remainingDiskAge = 0;
        NSDate *modifiedDate = resourceValues[cacheContentDateKey];
        if (maxDiskAge > 0) {
            remainingDiskAge = maxDiskAge - [now timeIntervalSinceDate:modifiedDate];
            if (remainingDiskAge <= 0) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
        } else {
            remainingDiskAge = [modifiedDate timeIntervalSinceDate:[NSDate distantPast]];
        }
        
        NSMutableDictionary *mResourceValues = resourceValues.mutableCopy;
        mResourceValues[kRemainingDiskAge] = @(remainingDiskAge);
        cacheFiles[fileURL] = mResourceValues;
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [fileManager removeItemAtURL:fileURL error:nil];
    }
    
    return cacheFiles;
}

+ (uint64_t)removeCacheFiles:(SDDiskCacheCachedFiles *)cacheFiles
               toMaxDiskSize:(NSUInteger)maxDiskSize
             withFileManager:(NSFileManager *)fileManager {
    if (maxDiskSize <= 0 || cacheFiles.count <= 0) {
        return 0;
    }
    
    NSUInteger currentCacheSize = 0;
    for (NSDictionary *resourceValues in cacheFiles.allValues) {
        NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
        currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
    }
    if (currentCacheSize <= maxDiskSize) {
        return 0;
    }
    
    NSUInteger originCacheSize = currentCacheSize;
    const NSUInteger desiredCacheSize = maxDiskSize / 2;
    
    // Sort the remaining cache files by their last modification time or last access time (oldest first).
    NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                             usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                 return [obj1[kRemainingDiskAge] compare:obj2[kRemainingDiskAge]];
                                                             }];
    CFTimeInterval timeout = SDImageCacheConfig.clearDiskTimeout;
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime end = 0;
    // Delete files until we fall below our desired cache size.
    for (NSURL *fileURL in sortedFiles) {
        if ([fileManager removeItemAtURL:fileURL error:nil]) {
            NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
            end = CFAbsoluteTimeGetCurrent();
            if (currentCacheSize < desiredCacheSize || (timeout > 0 && (end - start) > timeout)) {
                break;
            }
        }
    }
    return originCacheSize - currentCacheSize;
}

@end
