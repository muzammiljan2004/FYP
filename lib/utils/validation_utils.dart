class ValidationUtils {
  // Name validation - allows letters, spaces, and common name characters
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (trimmedValue.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Allow letters, spaces, hyphens, apostrophes, and dots (for names like "Mary Jane", "O'Connor", "St. John")
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return 'Name can only contain letters, spaces, hyphens, apostrophes, and dots';
    }
    
    // Check for consecutive spaces
    if (trimmedValue.contains('  ')) {
      return 'Name cannot contain consecutive spaces';
    }
    
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmedValue = value.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }
    
    if (trimmedValue.length > 254) {
      return 'Email is too long';
    }
    
    return null;
  }

  // Phone number validation (basic)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final trimmedValue = value.trim();
    
    // Remove all non-digit characters for validation
    final digitsOnly = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (value.length > 128) {
      return 'Password is too long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // CNIC validation (Pakistan format: 00000-0000000-0)
  static String? validateCNIC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC is required';
    }
    
    final trimmedValue = value.trim();
    
    // Remove all non-digit characters for validation
    final digitsOnly = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length != 13) {
      return 'CNIC must be exactly 13 digits';
    }
    
    // Check if it's a valid CNIC format (first 5 digits, then 7 digits, then 1 digit)
    final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d$');
    if (!cnicRegex.hasMatch(trimmedValue)) {
      return 'CNIC format should be: 00000-0000000-0';
    }
    
    return null;
  }

  // License number validation
  static String? validateLicense(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 5) {
      return 'License number must be at least 5 characters';
    }
    
    if (trimmedValue.length > 20) {
      return 'License number is too long';
    }
    
    // Allow alphanumeric characters and common separators
    final licenseRegex = RegExp(r'^[A-Za-z0-9\s\-\.]+$');
    if (!licenseRegex.hasMatch(trimmedValue)) {
      return 'License number can only contain letters, numbers, spaces, hyphens, and dots';
    }
    
    return null;
  }

  // Vehicle number validation
  static String? validateVehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vehicle number is required';
    }
    
    final trimmedValue = value.trim().toUpperCase();
    
    if (trimmedValue.length < 5) {
      return 'Vehicle number must be at least 5 characters';
    }
    
    if (trimmedValue.length > 15) {
      return 'Vehicle number is too long';
    }
    
    // Allow letters, numbers, and hyphens
    final vehicleRegex = RegExp(r'^[A-Z0-9\-]+$');
    if (!vehicleRegex.hasMatch(trimmedValue)) {
      return 'Vehicle number can only contain letters, numbers, and hyphens';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 10) {
      return 'Address must be at least 10 characters long';
    }
    
    if (trimmedValue.length > 200) {
      return 'Address is too long';
    }
    
    return null;
  }

  // Message/comment validation
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message is required';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 10) {
      return 'Message must be at least 10 characters long';
    }
    
    if (trimmedValue.length > 1000) {
      return 'Message is too long (maximum 1000 characters)';
    }
    
    return null;
  }

  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be exactly 6 digits';
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }

  // Required field validation (generic)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Dropdown validation
  static String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }
} 