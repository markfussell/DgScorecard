package org.dg

import grails.plugins.springsecurity.Secured

@Secured('isAuthenticated()')
class CourseController {
    static scaffold = true
}
