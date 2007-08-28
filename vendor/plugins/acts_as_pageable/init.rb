# Include hook code here
require 'acts_as_pageable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Pageable)
