
export const passwordRequirements = {
    minLength: 8,
    hasUpperCase: true,
    hasLowerCase: true,
    hasNumber: true,
}

export const validatePassword = (password: string): { isValid: boolean; message?: string } => {
    if (password.length < passwordRequirements.minLength) {
        return { isValid: false, message: `Password minimal ${passwordRequirements.minLength} karakter` }
    }
    if (passwordRequirements.hasUpperCase && !/[A-Z]/.test(password)) {
        return { isValid: false, message: 'Password harus mengandung huruf besar' }
    }
    if (passwordRequirements.hasLowerCase && !/[a-z]/.test(password)) {
        return { isValid: false, message: 'Password harus mengandung huruf kecil' }
    }
    if (passwordRequirements.hasNumber && !/\d/.test(password)) {
        return { isValid: false, message: 'Password harus mengandung angka' }
    }
    return { isValid: true }
}
