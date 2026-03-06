
// Define the allowed libraries manually to match @react-google-maps/api types
// 'localContext' was valid in older versions but might be missing or causing issues in the current installed version's types.
// We only use "places" so we can restrict it further if needed.

export type Library = "places" | "drawing" | "geometry" | "visualization";

// Shared libraries configuration to prevent "Loader must not be called again with different options" error
// We must use the same array reference or deep-equal array for all useJsApiLoader calls
export const GOOGLE_MAPS_LIBRARIES: Library[] = ["places"];
