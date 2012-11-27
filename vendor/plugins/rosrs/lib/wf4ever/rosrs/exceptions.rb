  # Exception class used to signal HTTP Session errors
  module ROSRS

    class Exception < Exception
    end

    class NotFoundException < Exception
    end

    class ForbiddenException < Exception
    end

    class UnauthorizedException < Exception
    end

    class ConflictException < Exception
    end

  end