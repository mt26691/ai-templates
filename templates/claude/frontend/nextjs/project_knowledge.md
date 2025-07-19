# Next.js Project Knowledge

## Framework Overview

Next.js is a React framework that provides:
- Server-Side Rendering (SSR) and Static Site Generation (SSG)
- File-based routing with App Router (recommended) or Pages Router
- Built-in API routes
- Image optimization
- Built-in CSS support
- TypeScript support out of the box

## Project Structure

### App Router (Recommended)
```
/app
  /api          # API routes
  /(auth)       # Route groups
  /dashboard    # Routes
    page.tsx    # Page component
    layout.tsx  # Layout wrapper
    loading.tsx # Loading UI
    error.tsx   # Error boundary
  /components   # Shared components
  /lib         # Utilities and helpers
  /styles      # Global styles
```

### Key Conventions
- `page.tsx` - Defines a route
- `layout.tsx` - Shared UI for a segment
- `loading.tsx` - Loading UI
- `error.tsx` - Error UI
- `not-found.tsx` - 404 page
- `route.ts` - API endpoint

## Routing Best Practices

### Dynamic Routes
```typescript
// app/posts/[id]/page.tsx
export default function Post({ params }: { params: { id: string } }) {
  return <div>Post {params.id}</div>
}
```

### Route Groups
- Use `(folder)` syntax to organize routes without affecting URL
- Example: `/(auth)/login` → `/login`

### Parallel Routes
- Use `@folder` syntax for rendering multiple pages in parallel
- Useful for modals, sidebars

### Intercepting Routes
- Use `(.)folder` syntax to intercept routes
- Useful for modal overlays

## Data Fetching

### Server Components (Default)
```typescript
// Runs on server, can be async
async function PostList() {
  const posts = await fetch('https://api.example.com/posts')
  return <div>{/* render posts */}</div>
}
```

### Client Components
```typescript
'use client'
// Use for interactivity, browser APIs
import { useState } from 'react'
```

### Data Fetching Patterns
- Use `fetch()` with Next.js extensions
- Implement proper caching strategies
- Use `revalidate` for ISR
- Implement loading and error states

## Performance Optimization

### Image Optimization
```typescript
import Image from 'next/image'
<Image src="/hero.jpg" alt="Hero" width={1200} height={600} priority />
```

### Font Optimization
```typescript
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'] })
```

### Lazy Loading
- Dynamic imports for code splitting
- Use `next/dynamic` for components
- Implement proper Suspense boundaries

## State Management

### Server State
- Use Server Components for initial data
- Implement Server Actions for mutations
- Use `revalidatePath` or `revalidateTag`

### Client State
- useState for component state
- Context for cross-component state
- Consider Zustand or Redux for complex apps

## Styling Approaches

### CSS Modules
```typescript
import styles from './Button.module.css'
<button className={styles.primary}>Click me</button>
```

### Tailwind CSS
- Recommended for rapid development
- Configure in `tailwind.config.js`
- Use with `cn()` utility for conditional classes

### CSS-in-JS
- Support for styled-components, emotion
- Requires additional configuration

## API Routes

### Route Handlers
```typescript
// app/api/posts/route.ts
export async function GET(request: Request) {
  return Response.json({ posts: [] })
}

export async function POST(request: Request) {
  const body = await request.json()
  return Response.json({ success: true })
}
```

### Middleware
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  // Add authentication, redirects, etc.
}

export const config = {
  matcher: '/api/:path*',
}
```

## Environment Variables

### Types
- `NEXT_PUBLIC_*` - Exposed to browser
- Others - Server-only

### Usage
```typescript
// Server Component
const apiKey = process.env.API_KEY

// Client Component
const publicUrl = process.env.NEXT_PUBLIC_API_URL
```

## SEO Optimization

### Metadata
```typescript
export const metadata = {
  title: 'Page Title',
  description: 'Page description',
  openGraph: { /* ... */ },
}
```

### Dynamic Metadata
```typescript
export async function generateMetadata({ params }) {
  return {
    title: `Post ${params.id}`,
  }
}
```

## Testing Strategy

### Unit Testing
- Jest + React Testing Library
- Test components in isolation
- Mock Next.js modules as needed

### Integration Testing
- Playwright or Cypress for E2E
- Test critical user flows
- API route testing

### Performance Testing
- Lighthouse CI
- Web Vitals monitoring
- Bundle analysis

## Deployment

### Vercel (Recommended)
- Zero-config deployment
- Automatic preview deployments
- Edge Functions support

### Self-Hosting
- Docker containerization
- Node.js server with `next start`
- Static export with `next export` (limited features)

## Common Patterns

### Authentication
- Use NextAuth.js or Auth0
- Implement middleware for protection
- Server-side session validation

### Internationalization
- Built-in i18n routing
- Use `next-intl` or similar
- Proper locale detection

### Error Handling
- Global error boundary
- API error responses
- Client-side error tracking

## Performance Checklist

- [ ] Enable Image Optimization
- [ ] Implement proper caching headers
- [ ] Use Server Components by default
- [ ] Minimize client-side JavaScript
- [ ] Implement proper loading states
- [ ] Monitor Core Web Vitals
- [ ] Use dynamic imports for large components
- [ ] Optimize third-party scripts