//
//  RCTMGLStyleValue.m
//  RCTMGL
//
//  Created by Nick Italiano on 9/11/17.
//  Copyright © 2017 Mapbox Inc. All rights reserved.
//

#import "RCTMGLStyleValue.h"
#import "RCTMGLUtils.h"
#import <React/RCTImageLoader.h>

@implementation RCTMGLStyleValue
{
    NSString *type;
    NSDictionary *payload;
}

- (void)setConfig:(NSDictionary *)config
{
    _config = config;
    type = (NSString*)config[@"styletype"];
    payload = (NSDictionary*)config[@"payload"];
}

- (NSString*)type
{
    return type;
}

- (NSDictionary*)payload
{
    return payload;
}

- (id)mglStyleValue
{
    if ([self isFunction]) {
        return [self makeStyleFunction];
    }
    
    id rawValue = self.payload[@"value"];
    
    if ([self.type isEqualToString:@"color"]) {
        rawValue = [RCTMGLUtils toColor:rawValue];
    } else if ([self.type isEqualToString:@"translate"]) {
        rawValue = [NSValue valueWithCGVector:[RCTMGLUtils toCGVector:rawValue]];
    }

    // check for overrides that handle special cases like NSArray vs CGVector
    NSDictionary *iosTypeOverride = self.payload[@"iosType"];
    if (iosTypeOverride != nil) {
        if ([iosTypeOverride isEqual:@"vector"]) {
            rawValue = [NSValue valueWithCGVector:[RCTMGLUtils toCGVector:rawValue]];
        }
    }
    
    id propertyValue = self.payload[@"propertyValue"];
    if (propertyValue != nil) {
        return @{ propertyValue: [NSExpression expressionForConstantValue:rawValue] };
    }
    
    return [NSExpression expressionForConstantValue:rawValue];
}

- (BOOL)isFunction
{
    return [type isEqualToString:@"function"];
}

- (BOOL)isTranslation
{
    return [type isEqualToString:@"translate"];
}

- (BOOL)isFunctionTypeSupported:(NSArray<NSString *> *)allowedFunctionTypes
{
    NSString *fnType = (NSString*)payload[@"fn"];
    
    for (NSString *curFnType in allowedFunctionTypes) {
        if ([curFnType isEqualToString:fnType]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSExpression*)makeStyleFunction
{
    NSString *fnType = (NSString*)payload[@"fn"];
    NSArray<NSArray<NSDictionary *> *> *rawStops = payload[@"stops"];
    NSString *interpolationMode = payload[@"mode"];
    NSString *attributeName = payload[@"attributeName"];
    
    NSMutableDictionary<id, id> *stops = nil;
    if (rawStops.count > 0) {
        stops = [[NSMutableDictionary alloc] init];
        
        for (NSArray *rawStop in rawStops) {
            NSDictionary *jsStopKey = rawStop[0];
            NSDictionary *jsStopValue = rawStop[1];
            RCTMGLStyleValue *rctStyleValue = [RCTMGLStyleValue make:jsStopValue];
            stops[[self _getStopKey:jsStopKey]] = rctStyleValue.mglStyleValue;
        }
    }

    if ([fnType isEqualToString:@"camera"]) {
        if ([interpolationMode isEqualToString:@"linear"]) {
            return  [NSExpression expressionWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", stops];
        } else if ([interpolationMode isEqualToString:@"exponential"]) {
            return  [NSExpression expressionWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1, %@)", stops];
        } else if ([interpolationMode isEqualToString:@"categorical"]) {
            NSString * expressionFormat = @"MGL_MATCH(";
            NSMutableArray * arrayValues = [[NSMutableArray alloc] init];
            for(id key in stops) {
                id value = [stops objectForKey:key];
                NSString * formattedValue = [NSString stringWithFormat:@"'%@', ", key];
                [arrayValues addObject:value];
                expressionFormat = [expressionFormat stringByAppendingString:formattedValue];
                expressionFormat = [expressionFormat stringByAppendingString:@"%@, "];
                
            }
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            [arrayValues addObject:[UIColor blackColor]];// default color
            return [NSExpression expressionWithFormat:expressionFormat argumentArray:arrayValues];
        } else if ([interpolationMode isEqualToString:@"interval"]) {
            NSString * expressionFormat = @"mgl_step:from:stops:($zoomLevel, 0, ";
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            return [NSExpression expressionWithFormat:expressionFormat, stops];
        } else if ([interpolationMode isEqualToString:@"identity"]) {
            return nil;
        }
    } else if ([fnType isEqualToString:@"source"]) {
        if ([interpolationMode isEqualToString:@"linear"]) {
            NSString * expressionFormat = [NSString stringWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:(%@, 'linear', nill, ", attributeName];
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            return [NSExpression expressionWithFormat:expressionFormat, stops];
        } else if ([interpolationMode isEqualToString:@"exponential"]) {
            NSString * expressionFormat = [NSString stringWithFormat:@"mgl_interpolate:withCurveType:parameters:stops:(%@, 'exponential', 1, ", attributeName];
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            return [NSExpression expressionWithFormat:expressionFormat, stops];
        } else if ([interpolationMode isEqualToString:@"categorical"]) {
            NSString * expressionFormat = [NSString stringWithFormat:@"MGL_MATCH(%@, ", attributeName];
            NSMutableArray * arrayValues = [[NSMutableArray alloc] init];
            for(id key in stops) {
                id value = [stops objectForKey:key];
                NSString * formattedValue = [NSString stringWithFormat:@"'%@', ", key];
                [arrayValues addObject:value];
                expressionFormat = [expressionFormat stringByAppendingString:formattedValue];
                expressionFormat = [expressionFormat stringByAppendingString:@"%@, "];
            }
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            [arrayValues addObject:[UIColor blackColor]];// default color
            return [NSExpression expressionWithFormat:expressionFormat argumentArray:arrayValues];
        } else if ([interpolationMode isEqualToString:@"interval"]) {
            NSString * expressionFormat = [NSString stringWithFormat:@"mgl_step:from:stops:(%@, 0, ", attributeName];
            expressionFormat = [expressionFormat stringByAppendingString:@"%@)"];
            return [NSExpression expressionWithFormat:expressionFormat, stops];
        } else if ([interpolationMode isEqualToString:@"identity"]) {
            NSString * expressionFormat = [NSString stringWithFormat:@"%@", attributeName];
            return [NSExpression expressionForKeyPath:expressionFormat];
        }
    } else if ([fnType isEqualToString:@"composite"]) {
        return nil;
    }
    return nil;
}

- (MGLTransition)getTransition
{
    if (![self.type isEqualToString:@"transition"]) {
        return MGLTransitionMake(0, 0);
    }
    
    NSDictionary *config = self.payload[@"value"];
    if (config == nil) {
        return MGLTransitionMake(0, 0);
    }
    
    NSNumber *duration = config[@"duration"];
    NSNumber *delay = config[@"delay"];
    
    return MGLTransitionMake([duration doubleValue], [delay doubleValue]);
}

- (NSExpression*)getSphericalPosition
{
    NSArray<NSNumber*> *values = self.payload[@"value"];
    
    CGFloat radial = [values[0] floatValue];
    CLLocationDistance azimuthal = [values[1] doubleValue];
    CLLocationDistance polar = [values[2] doubleValue];
    
    MGLSphericalPosition pos = MGLSphericalPositionMake(radial, azimuthal, polar);
    return [NSExpression expressionForConstantValue:[NSValue valueWithMGLSphericalPosition:pos]];
}

- (BOOL)isVisible
{
    id value = self.payload[@"value"];
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    return [value isEqualToString:@"visible"];
}

- (id)_getStopKey:(NSDictionary *)jsStopKey
{
    NSString *payloadKey = @"value";
    NSString *type = jsStopKey[@"type"];
    
    if ([type isEqualToString:@"number"]) {
        return (NSNumber *)jsStopKey[payloadKey];
    } else if ([type isEqualToString:@"boolean"]) {
        return [NSNumber numberWithBool:jsStopKey[payloadKey]];
    } else {
        return (NSString *)jsStopKey[payloadKey];
    }
}

+ (RCTMGLStyleValue*)make:(NSDictionary*)config;
{
    RCTMGLStyleValue *styleValue = [[RCTMGLStyleValue alloc] init];
    styleValue.config = config;
    return styleValue;
}

@end
