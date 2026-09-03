package com.gnn.roadsurvey.security;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RequireAuth {
    // Empty = any authenticated role. Otherwise restrict to the roles listed.
    String[] roles() default {};
}
