// import React, { createContext, useContext, useState } from "react";

// const ThemeContext = createContext();

// // Provider that wraps the app
// export const ThemeProvider = ({ children }) => {
//   const [theme, setTheme] = useState("light"); // default light

//   // apply the theme to <html> attribute for CSS
//   React.useEffect(() => {
//     document.documentElement.setAttribute("data-theme", theme);
//   }, [theme]);

//   return (
//     <ThemeContext.Provider value={{ theme, setTheme }}>
//       {children}
//     </ThemeContext.Provider>
//   );
// };

// // custom hook for easier usage
// export const useTheme = () => useContext(ThemeContext);
