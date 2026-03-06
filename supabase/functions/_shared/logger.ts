
export const sensitiveKeys = [
    "password",
    "token",
    "access_token",
    "refresh_token",
    "Authorization",
    "authorization",
    "secret",
    "apikey"
];

function sanitize(obj: any): any {
    if (typeof obj !== "object" || obj === null) {
        return obj;
    }

    if (Array.isArray(obj)) {
        return obj.map(sanitize);
    }

    const sanitized: any = {};
    for (const key in obj) {
        if (sensitiveKeys.some(k => k.toLowerCase() === key.toLowerCase())) {
            sanitized[key] = "***SANITIZED***";
        } else {
            sanitized[key] = sanitize(obj[key]);
        }
    }
    return sanitized;
}

export const logger = {
    info: (message: string, data?: any) => {
        console.log(message, data ? JSON.stringify(sanitize(data)) : "");
    },
    error: (message: string, error?: any) => {
        let errorData = error;
        if (error instanceof Error) {
            // Standard errors are usually safe, but custom properties might not be.
            // We'll trust Error.message and stack, but sanitize if it's an object.
            console.error(message, error.message, error.stack);
        } else {
            console.error(message, error ? JSON.stringify(sanitize(error)) : "");
        }
    }
};
