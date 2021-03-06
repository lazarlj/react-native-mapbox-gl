package com.mapbox.rctmgl.location;

import com.mapbox.mapboxsdk.location.modes.RenderMode;

/**
 * Created by nickitaliano on 12/13/17.
 */

public class UserTrackingMode {
    public static final int NONE = 0;
    public static final int FOLLOW = 1;
    public static final int FollowWithCourse = 2;
    public static final int FollowWithHeading = 3;

    public static int getMapLayerMode(int mode, boolean isShowUserLocation) {
        if (!isShowUserLocation) {
            return NONE;
        } else if (mode == FOLLOW) {
            return RenderMode.NORMAL;
        } else if (mode == FollowWithCourse) {
            return RenderMode.GPS;
        } else if (mode == FollowWithHeading) {
            return RenderMode.COMPASS;
        } else {
            return NONE;
        }
    }

    public static boolean isUserGesture(int reason) {
        return reason == 1 || reason == 2; // user gesture or animation
    }
}
