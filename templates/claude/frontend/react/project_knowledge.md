# React Frontend Project Knowledge

## Project Overview

This is a modern React application built with TypeScript, focusing on component-based architecture, functional programming patterns, and modern React practices. The project emphasizes performance, accessibility, and maintainability.

## Technology Stack

- **Framework**: React 18+ with TypeScript
- **State Management**: Context API, React Query, or Zustand
- **Routing**: React Router v6+
- **Styling**: Tailwind CSS / Styled Components / CSS Modules
- **Build Tool**: Vite / Next.js
- **Testing**: Jest + React Testing Library
- **Form Handling**: React Hook Form with Zod validation

## Architecture Patterns

- **Component-based architecture**: Reusable, composable components
- **Functional programming**: Hooks-based approach
- **Composition over inheritance**: Building complex UI from simple components
- **Container/Presentational pattern**: Separation of logic and UI
- **Custom hooks**: Reusable stateful logic

## Project Structure

```
src/
├── components/           # Reusable UI components
│   ├── ui/              # Basic UI components (Button, Input, etc.)
│   ├── forms/           # Form components
│   └── layout/          # Layout components
├── pages/               # Page components
├── features/            # Feature-specific components and logic
│   ├── auth/
│   ├── dashboard/
│   └── profile/
├── hooks/               # Custom React hooks
├── services/            # API services and external integrations
├── utils/               # Utility functions
├── types/               # TypeScript type definitions
├── constants/           # Application constants
├── context/             # React Context providers
├── styles/              # Global styles and theme
└── assets/              # Static assets
```

## Development Guidelines

### Component Development

- Use functional components with hooks
- Implement proper TypeScript interfaces for props
- Keep components small and focused (Single Responsibility Principle)
- Use composition pattern for complex components
- Implement proper error boundaries

### State Management

- Use local state (useState) for component-specific data
- Use React Context for app-wide state that doesn't change frequently
- Consider React Query for server state management
- Use Zustand for complex client-side state if needed

### Hooks Best Practices

- Follow Rules of Hooks (only call at top level)
- Use dependency arrays correctly in useEffect
- Create custom hooks for reusable logic
- Use useCallback and useMemo judiciously for performance

### Styling Approach

- Use consistent design tokens and variables
- Implement responsive design from the start
- Follow mobile-first approach
- Use CSS-in-JS or utility-first CSS (Tailwind)
- Maintain consistent spacing and typography

### Form Handling

- Use React Hook Form for complex forms
- Implement proper validation with Zod or Yup
- Handle form errors gracefully
- Provide good UX with loading states and feedback

## Common Patterns

### Compound Component Pattern

```typescript
// components/Modal/Modal.tsx
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

const Modal: React.FC<ModalProps> & {
  Header: React.FC<{ children: React.ReactNode }>;
  Body: React.FC<{ children: React.ReactNode }>;
  Footer: React.FC<{ children: React.ReactNode }>;
} = ({ isOpen, onClose, children }) => {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        {children}
      </div>
    </div>
  );
};

Modal.Header = ({ children }) => <div className="modal-header">{children}</div>;
Modal.Body = ({ children }) => <div className="modal-body">{children}</div>;
Modal.Footer = ({ children }) => <div className="modal-footer">{children}</div>;
```

### Custom Hook Pattern

```typescript
// hooks/useLocalStorage.ts
import { useState, useEffect } from 'react';

function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore =
        value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  };

  return [storedValue, setValue] as const;
}
```

### Context Provider Pattern

```typescript
// context/ThemeContext.tsx
interface ThemeContextType {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [theme, setTheme] = useLocalStorage<'light' | 'dark'>('theme', 'light');

  const toggleTheme = useCallback(() => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  }, [setTheme]);

  const value = useMemo(() => ({ theme, toggleTheme }), [theme, toggleTheme]);

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};
```

## Key Dependencies

- `react` & `react-dom` - Core React libraries
- `react-router-dom` - Client-side routing
- `@tanstack/react-query` - Server state management
- `react-hook-form` - Form handling
- `zod` - Schema validation
- `axios` - HTTP client
- `tailwindcss` - Utility-first CSS framework
- `framer-motion` - Animation library
- `react-hot-toast` - Toast notifications

## Performance Optimization

- Use React.memo for components that render frequently
- Implement code splitting with React.lazy
- Use useMemo for expensive calculations
- Use useCallback for event handlers passed to children
- Optimize images and assets
- Implement virtual scrolling for large lists

## Testing Strategy

- Unit tests for individual components
- Integration tests for feature workflows
- Test user interactions, not implementation details
- Mock external dependencies and API calls
- Test accessibility with screen readers
- Use MSW (Mock Service Worker) for API mocking

## Accessibility Guidelines

- Use semantic HTML elements
- Implement proper ARIA attributes
- Ensure keyboard navigation works
- Maintain proper color contrast ratios
- Provide alt text for images
- Test with screen readers
- Implement focus management

## Error Handling

- Implement Error Boundaries for component trees
- Use react-error-boundary for better error UX
- Handle async errors in useEffect
- Provide fallback UI for errors
- Log errors to monitoring service
- Show user-friendly error messages

## Security Considerations

- Sanitize user inputs to prevent XSS
- Use HTTPS for all API communications
- Implement proper authentication flow
- Validate data on both client and server
- Use Content Security Policy (CSP)
- Avoid storing sensitive data in localStorage

## Build and Deployment

- Use environment variables for configuration
- Implement proper build optimization
- Use service workers for offline functionality
- Implement proper error monitoring (Sentry)
- Use CI/CD for automated testing and deployment
- Optimize bundle size with tree shaking

## Code Quality Tools

- ESLint with React and TypeScript rules
- Prettier for consistent code formatting
- Husky for pre-commit hooks
- TypeScript for type safety
- React DevTools for debugging
- Lighthouse for performance auditing

## State Management Patterns

- Local state for component-specific data
- Context for theme, user auth, and rarely changing global state
- React Query for server state and caching
- URL state for shareable application state
- Form state with React Hook Form
- Consider external state management (Zustand) for complex scenarios
