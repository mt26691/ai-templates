# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this Next.js frontend project.

## Project Overview

A modern, production-ready Next.js 14+ application built with TypeScript, featuring:
- App Router architecture for improved performance and DX
- Server and Client Components optimization
- Internationalization (i18n) support
- SEO and accessibility first approach
- Comprehensive testing strategy (Jest + Playwright)
- Storybook for component development
- Performance monitoring and optimization

## Tech Stack

### Core
- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript 5+
- **Styling**: Tailwind CSS + CSS Modules
- **State Management**: Zustand / React Context
- **Data Fetching**: React Query + fetch

### Development
- **Component Development**: Storybook 7+
- **Testing**: Jest + React Testing Library + Playwright
- **Linting**: ESLint + Prettier + Husky
- **Commit Convention**: Commitlint with Conventional Commits
- **Package Manager**: pnpm (preferred) / npm / yarn

### Infrastructure
- **Deployment**: Vercel / Docker
- **CDN**: Cloudflare / Vercel Edge Network
- **Analytics**: Vercel Analytics + Google Analytics
- **Monitoring**: Sentry + Vercel Speed Insights

## Environment Setup

### Prerequisites
```bash
# Required
- Node.js 18.17+ (use nvm)
- pnpm 8+ (npm install -g pnpm)
- Git

# Optional but recommended
- Docker Desktop
- VS Code with recommended extensions
```

### Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd <project-name>

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env.local

# Run development server
pnpm dev

# Open browser
open http://localhost:3000
```

### Environment Files
```
.env.example          # Template with all variables (committed)
.env.local           # Local development (gitignored)
.env.test            # Test environment
.env.production      # Production values (CI/CD managed)
```

## Directory Structure

```
src/
├── app/                    # App Router pages and layouts
│   ├── (auth)/            # Route groups
│   ├── api/               # API routes
│   ├── [locale]/          # i18n dynamic routes
│   │   ├── layout.tsx     # Root layout
│   │   ├── page.tsx       # Home page
│   │   └── (routes)/      # Other pages
│   ├── error.tsx          # Error boundary
│   ├── not-found.tsx      # 404 page
│   └── global-error.tsx   # Global error boundary
├── components/            # React components
│   ├── ui/               # Base UI components
│   ├── features/         # Feature-specific components
│   ├── layouts/          # Layout components
│   └── providers/        # Context providers
├── hooks/                # Custom React hooks
├── lib/                  # Utilities and configs
│   ├── api/             # API client utilities
│   ├── auth/            # Authentication helpers
│   ├── db/              # Database utilities
│   └── utils/           # General utilities
├── services/            # Business logic services
├── stores/              # Zustand stores
├── styles/              # Global styles
├── types/               # TypeScript types
├── locales/             # i18n translations
└── config/              # App configuration
    ├── env.ts           # Environment validation
    ├── site.ts          # Site metadata
    └── features.ts      # Feature toggles
```

## App Router Guidelines

### File Conventions
```typescript
// app/[locale]/products/page.tsx
import { Metadata } from 'next'

// Metadata generation
export async function generateMetadata({ params }): Promise<Metadata> {
  return {
    title: 'Products',
    description: 'Browse our products'
  }
}

// Static params generation
export async function generateStaticParams() {
  return [
    { locale: 'en' },
    { locale: 'es' },
    { locale: 'fr' }
  ]
}

// Page component
export default async function ProductsPage({ params, searchParams }) {
  const products = await getProducts(searchParams)
  
  return <ProductList products={products} />
}
```

### Route Organization
```
app/
├── (marketing)/          # Public routes
│   ├── about/
│   └── contact/
├── (shop)/              # E-commerce routes
│   ├── products/
│   └── cart/
├── (auth)/              # Auth routes
│   ├── login/
│   └── register/
└── dashboard/           # Protected routes
    ├── layout.tsx       # Auth check
    └── settings/
```

## Server Components

### Best Practices
```typescript
// app/components/ProductList.tsx
// This is a Server Component by default

import { db } from '@/lib/db'

async function ProductList({ category }: { category: string }) {
  // Direct database access in Server Components
  const products = await db.product.findMany({
    where: { category },
    select: {
      id: true,
      name: true,
      price: true,
      image: true
    }
  })

  return (
    <div className="grid grid-cols-3 gap-4">
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}

// Server Component composition
export default async function ProductsSection() {
  return (
    <>
      <ProductList category="featured" />
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductList category="new" />
      </Suspense>
    </>
  )
}
```

### Data Fetching
```typescript
// Deduped fetch requests
async function getUser(id: string) {
  const res = await fetch(`/api/users/${id}`, {
    next: { revalidate: 3600 }, // Cache for 1 hour
    cache: 'force-cache' // or 'no-store' for dynamic
  })
  
  if (!res.ok) throw new Error('Failed to fetch user')
  
  return res.json()
}
```

## Client Components

### When to Use
```typescript
'use client'

// components/InteractiveChart.tsx
import { useState, useEffect } from 'react'
import { Chart } from '@/components/ui/Chart'

export function InteractiveChart({ data }) {
  const [filter, setFilter] = useState('all')
  
  // Client-side interactivity
  useEffect(() => {
    // Browser APIs
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  return (
    <div>
      <FilterButtons value={filter} onChange={setFilter} />
      <Chart data={filterData(data, filter)} />
    </div>
  )
}
```

### Server-Client Boundary
```typescript
// Server Component
async function ProductPage({ id }: { id: string }) {
  const product = await getProduct(id)
  
  return (
    <>
      <ProductDetails product={product} />
      {/* Client Component for interactivity */}
      <AddToCartButton productId={id} />
    </>
  )
}

// Client Component
'use client'
function AddToCartButton({ productId }: { productId: string }) {
  const [loading, setLoading] = useState(false)
  
  const handleAddToCart = async () => {
    setLoading(true)
    await addToCart(productId)
    setLoading(false)
  }
  
  return (
    <button onClick={handleAddToCart} disabled={loading}>
      {loading ? 'Adding...' : 'Add to Cart'}
    </button>
  )
}
```

## Storybook Components

### Component Story Format 3.0
```typescript
// components/ui/Button/Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from './Button'

const meta = {
  title: 'UI/Button',
  component: Button,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'danger']
    }
  }
} satisfies Meta<typeof Button>

export default meta
type Story = StoryObj<typeof meta>

export const Primary: Story = {
  args: {
    variant: 'primary',
    children: 'Click me',
  },
}

export const WithIcon: Story = {
  args: {
    variant: 'secondary',
    children: 'Download',
    icon: <DownloadIcon />,
  },
}

// Interaction testing
export const Clickable: Story = {
  args: {
    children: 'Click me',
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)
    const button = await canvas.getByRole('button')
    await userEvent.click(button)
    await expect(button).toHaveFocus()
  },
}
```

### Storybook Configuration
```javascript
// .storybook/main.js
module.exports = {
  stories: ['../src/**/*.stories.@(js|jsx|ts|tsx|mdx)'],
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-a11y',
    '@storybook/addon-interactions',
    'storybook-addon-next',
  ],
  framework: {
    name: '@storybook/nextjs',
    options: {},
  },
}
```

## Image Optimization

### Next/Image Best Practices
```typescript
import Image from 'next/image'

// Static import with blur placeholder
import heroImage from '@/public/hero.jpg'

export function Hero() {
  return (
    <Image
      src={heroImage}
      alt="Hero image"
      priority // Load immediately
      placeholder="blur" // Show blur while loading
      quality={90} // Higher quality for hero
    />
  )
}

// Dynamic images with proper sizing
export function ProductImage({ src, alt }) {
  return (
    <div className="relative aspect-square">
      <Image
        src={src}
        alt={alt}
        fill
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        className="object-cover"
      />
    </div>
  )
}

// Responsive images
export function ResponsiveImage({ desktop, mobile, alt }) {
  return (
    <picture>
      <source media="(min-width: 768px)" srcSet={desktop} />
      <Image src={mobile} alt={alt} width={800} height={600} />
    </picture>
  )
}
```

### Image Configuration
```javascript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/images/**',
      },
    ],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
}
```

## i18n Configuration

### Setup
```typescript
// config/i18n.ts
export const locales = ['en', 'es', 'fr', 'de'] as const
export const defaultLocale = 'en' as const

export type Locale = (typeof locales)[number]

// i18n routing
export const i18n = {
  locales,
  defaultLocale,
}
```

### Middleware
```typescript
// middleware.ts
import { NextRequest } from 'next/server'
import { i18n } from '@/config/i18n'

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname
  
  // Check if locale is in pathname
  const pathnameHasLocale = i18n.locales.some(
    locale => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  )

  if (pathnameHasLocale) return

  // Redirect to default locale
  const locale = getLocale(request)
  request.nextUrl.pathname = `/${locale}${pathname}`
  return Response.redirect(request.nextUrl)
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

### Translation Hook
```typescript
// hooks/useTranslation.ts
'use client'

import { useParams } from 'next/navigation'
import { translations } from '@/locales'

export function useTranslation() {
  const params = useParams()
  const locale = params.locale as Locale || 'en'
  
  const t = (key: string) => {
    return translations[locale][key] || key
  }
  
  return { t, locale }
}
```

## SEO Best Practices

### Metadata API
```typescript
// app/[locale]/products/[id]/page.tsx
import { Metadata } from 'next'

export async function generateMetadata({ params }): Promise<Metadata> {
  const product = await getProduct(params.id)
  
  return {
    title: `${product.name} | My Store`,
    description: product.description,
    openGraph: {
      title: product.name,
      description: product.description,
      images: [
        {
          url: product.image,
          width: 1200,
          height: 630,
          alt: product.name,
        }
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: product.name,
      description: product.description,
      images: [product.image],
    },
    alternates: {
      canonical: `/products/${product.id}`,
      languages: {
        'en': `/en/products/${product.id}`,
        'es': `/es/products/${product.id}`,
      },
    },
  }
}
```

### Structured Data
```typescript
// components/ProductSchema.tsx
export function ProductSchema({ product }) {
  const schema = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: product.description,
    image: product.images,
    sku: product.sku,
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'USD',
      availability: product.inStock 
        ? 'https://schema.org/InStock' 
        : 'https://schema.org/OutOfStock',
    },
    review: product.reviews.map(review => ({
      '@type': 'Review',
      reviewRating: {
        '@type': 'Rating',
        ratingValue: review.rating,
      },
      author: {
        '@type': 'Person',
        name: review.author,
      },
    })),
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  )
}
```

## Accessibility Checks

### Component Accessibility
```typescript
// components/ui/Modal.tsx
'use client'

import { useEffect, useRef } from 'react'
import { createPortal } from 'react-dom'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: React.ReactNode
}

export function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (isOpen) {
      // Focus trap
      closeButtonRef.current?.focus()
      
      // Prevent body scroll
      document.body.style.overflow = 'hidden'
      
      // Handle escape key
      const handleEscape = (e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose()
      }
      
      document.addEventListener('keydown', handleEscape)
      
      return () => {
        document.body.style.overflow = ''
        document.removeEventListener('keydown', handleEscape)
      }
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  return createPortal(
    <div
      role="dialog"
      aria-labelledby="modal-title"
      aria-modal="true"
      className="fixed inset-0 z-50"
    >
      <div
        className="bg-black/50"
        onClick={onClose}
        aria-hidden="true"
      />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <div className="bg-white rounded-lg max-w-md w-full p-6">
          <h2 id="modal-title" className="text-xl font-bold mb-4">
            {title}
          </h2>
          {children}
          <button
            ref={closeButtonRef}
            onClick={onClose}
            className="mt-4 px-4 py-2 bg-gray-200 rounded"
            aria-label="Close modal"
          >
            Close
          </button>
        </div>
      </div>
    </div>,
    document.body
  )
}
```

### Automated Testing
```typescript
// components/ui/Button/Button.test.tsx
import { render, screen } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import { Button } from './Button'

expect.extend(toHaveNoViolations)

describe('Button Accessibility', () => {
  it('should have no accessibility violations', async () => {
    const { container } = render(
      <Button variant="primary">Click me</Button>
    )
    
    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  it('should have proper ARIA attributes', () => {
    render(
      <Button disabled aria-label="Save document">
        Save
      </Button>
    )
    
    const button = screen.getByRole('button', { name: 'Save document' })
    expect(button).toHaveAttribute('aria-disabled', 'true')
  })
})
```

## Environment Schema Validation

### Zod Validation
```typescript
// config/env.ts
import { z } from 'zod'

const envSchema = z.object({
  // Public variables
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_API_URL: z.string().url(),
  NEXT_PUBLIC_GA_ID: z.string().optional(),
  
  // Server-only variables
  DATABASE_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(32),
  NEXTAUTH_URL: z.string().url(),
  
  // API Keys
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
  
  // Feature flags
  ENABLE_ANALYTICS: z.enum(['true', 'false']).transform(v => v === 'true'),
  MAINTENANCE_MODE: z.enum(['true', 'false']).transform(v => v === 'true'),
})

// Validate at build time
const parsed = envSchema.safeParse(process.env)

if (!parsed.success) {
  console.error('❌ Invalid environment variables:')
  console.error(parsed.error.flatten().fieldErrors)
  throw new Error('Invalid environment variables')
}

export const env = parsed.data

// Type-safe usage
// import { env } from '@/config/env'
// const apiUrl = env.NEXT_PUBLIC_API_URL
```

## Feature Toggle System

### Implementation
```typescript
// config/features.ts
import { env } from './env'

export const features = {
  // Static feature flags
  newCheckout: true,
  socialLogin: false,
  
  // Dynamic feature flags
  analytics: env.ENABLE_ANALYTICS,
  maintenance: env.MAINTENANCE_MODE,
  
  // User-based flags
  betaFeatures: (userId: string) => {
    const betaUsers = ['user1', 'user2']
    return betaUsers.includes(userId)
  },
  
  // Percentage rollout
  experimentalSearch: (userId: string) => {
    const hash = userId.split('').reduce((acc, char) => {
      return acc + char.charCodeAt(0)
    }, 0)
    return hash % 100 < 20 // 20% of users
  },
}

// Feature flag hook
export function useFeature(feature: keyof typeof features) {
  const userId = useUserId() // Get from auth context
  
  const value = features[feature]
  
  if (typeof value === 'function') {
    return value(userId)
  }
  
  return value
}
```

### Feature Component
```typescript
// components/Feature.tsx
interface FeatureProps {
  flag: keyof typeof features
  fallback?: React.ReactNode
  children: React.ReactNode
}

export function Feature({ flag, fallback = null, children }: FeatureProps) {
  const enabled = useFeature(flag)
  
  if (!enabled) return <>{fallback}</>
  
  return <>{children}</>
}

// Usage
<Feature flag="newCheckout" fallback={<OldCheckout />}>
  <NewCheckout />
</Feature>
```

## Commitlint Rules

### Configuration
```javascript
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Code style
        'refactor', // Code refactoring
        'perf',     // Performance
        'test',     // Tests
        'chore',    // Maintenance
        'revert',   // Revert commit
        'ci',       // CI/CD
      ],
    ],
    'subject-case': [2, 'never', ['upper-case', 'pascal-case']],
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 100],
  },
}
```

### Git Hooks
```json
// package.json
{
  "scripts": {
    "prepare": "husky install"
  },
  "husky": {
    "hooks": {
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS",
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
```

### Commit Examples
```bash
# Good commits
feat: add user authentication with NextAuth
fix: resolve cart total calculation error
docs: update API documentation for v2
perf: optimize image loading with lazy loading
test: add unit tests for checkout flow

# Bad commits (will be rejected)
Add feature       # Missing type
FEAT: Add login   # Wrong case
feat: implemented user authentication system with NextAuth.js and added Google OAuth # Too long
```

## Branch Naming Convention

### Format
```
type/scope-description
type/JIRA-123-description
```

### Types
- `feature/` - New features
- `fix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `test/` - Test additions/updates
- `chore/` - Maintenance tasks
- `perf/` - Performance improvements

### Examples
```bash
feature/user-authentication
fix/cart-calculation-error
hotfix/payment-gateway-timeout
refactor/component-structure
docs/api-v2-updates
test/checkout-flow
chore/update-dependencies
perf/image-optimization
```

## Static vs Server Props

### When to Use Each

#### Static Generation (Default)
```typescript
// Use for pages that can be pre-rendered
// app/blog/page.tsx
export default async function BlogPage() {
  const posts = await getPosts() // Fetched at build time
  
  return <BlogList posts={posts} />
}

// With revalidation
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { revalidate: 3600 } // Revalidate every hour
  })
  return res.json()
}
```

#### Dynamic Rendering
```typescript
// Use for personalized or frequently changing content
// app/dashboard/page.tsx
import { cookies } from 'next/headers'

export default async function DashboardPage() {
  const cookieStore = cookies()
  const token = cookieStore.get('token')
  
  // This makes the page dynamic
  const userData = await getUserData(token)
  
  return <Dashboard data={userData} />
}
```

#### Hybrid Approach
```typescript
// Static shell with dynamic content
export default async function ProductPage({ params }) {
  // Static product data
  const product = await getProduct(params.id)
  
  return (
    <>
      <ProductInfo product={product} />
      <Suspense fallback={<ReviewsSkeleton />}>
        {/* Dynamic reviews loaded on demand */}
        <ProductReviews productId={params.id} />
      </Suspense>
    </>
  )
}
```

## Performance Metrics

### Core Web Vitals Monitoring
```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
```

### Custom Performance Monitoring
```typescript
// hooks/usePerformance.ts
export function usePerformance() {
  useEffect(() => {
    // First Input Delay
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        console.log('FID:', entry.processingStart - entry.startTime)
      }
    }).observe({ entryTypes: ['first-input'] })
    
    // Cumulative Layout Shift
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        console.log('CLS:', entry.value)
      }
    }).observe({ entryTypes: ['layout-shift'] })
    
    // Largest Contentful Paint
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        console.log('LCP:', entry.startTime)
      }
    }).observe({ entryTypes: ['largest-contentful-paint'] })
  }, [])
}
```

## Caching Strategies

### Data Cache
```typescript
// Fetch with caching
async function getProducts() {
  const res = await fetch('https://api.example.com/products', {
    next: {
      revalidate: 3600, // Cache for 1 hour
      tags: ['products'] // Cache tags for invalidation
    }
  })
  return res.json()
}

// On-demand revalidation
import { revalidateTag, revalidatePath } from 'next/cache'

export async function createProduct(data) {
  await db.product.create({ data })
  
  // Invalidate cache
  revalidateTag('products')
  revalidatePath('/products')
}
```

### Route Segment Config
```typescript
// app/products/page.tsx
export const dynamic = 'force-static' // or 'force-dynamic'
export const revalidate = 3600 // seconds
export const fetchCache = 'force-cache' // or 'force-no-store'
```

### Client-Side Caching
```typescript
// React Query setup
// lib/query-client.ts
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      refetchOnWindowFocus: false,
    },
  },
})

// Usage in components
function useProducts() {
  return useQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
    staleTime: 30 * 60 * 1000, // 30 minutes
  })
}
```

## ESLint Configuration

### Next.js Specific Rules
```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'next/core-web-vitals',
    'plugin:@typescript-eslint/recommended',
    'plugin:tailwindcss/recommended',
    'prettier',
  ],
  plugins: ['@typescript-eslint', 'tailwindcss'],
  rules: {
    // Next.js specific
    '@next/next/no-html-link-for-pages': 'error',
    '@next/next/no-img-element': 'error',
    
    // TypeScript
    '@typescript-eslint/no-unused-vars': ['error', { 
      argsIgnorePattern: '^_',
      varsIgnorePattern: '^_',
    }],
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    
    // React
    'react/prop-types': 'off',
    'react/react-in-jsx-scope': 'off',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    
    // Import sorting
    'import/order': ['error', {
      groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
      'newlines-between': 'always',
      alphabetize: { order: 'asc' },
    }],
    
    // Tailwind
    'tailwindcss/classnames-order': 'warn',
    'tailwindcss/no-custom-classname': 'warn',
  },
}
```

## Unit Tests (Jest)

### Setup
```javascript
// jest.config.js
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
}

module.exports = createJestConfig(customJestConfig)
```

### Component Testing
```typescript
// components/ui/Button/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('handles click events', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)
    
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('applies variant styles', () => {
    render(<Button variant="danger">Delete</Button>)
    const button = screen.getByRole('button')
    
    expect(button).toHaveClass('bg-red-500')
  })
})
```

### Hook Testing
```typescript
// hooks/useDebounce.test.ts
import { renderHook, act } from '@testing-library/react'
import { useDebounce } from './useDebounce'

describe('useDebounce', () => {
  jest.useFakeTimers()

  it('debounces value changes', () => {
    const { result, rerender } = renderHook(
      ({ value, delay }) => useDebounce(value, delay),
      { initialProps: { value: 'initial', delay: 500 } }
    )

    expect(result.current).toBe('initial')

    // Update value
    rerender({ value: 'updated', delay: 500 })
    expect(result.current).toBe('initial')

    // Fast-forward time
    act(() => {
      jest.advanceTimersByTime(500)
    })

    expect(result.current).toBe('updated')
  })
})
```

## Integration Tests (Playwright)

### Configuration
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
})
```

### E2E Test Example
```typescript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test('user can sign up', async ({ page }) => {
    await page.goto('/signup')
    
    // Fill form
    await page.fill('[name="email"]', 'test@example.com')
    await page.fill('[name="password"]', 'Password123!')
    await page.fill('[name="confirmPassword"]', 'Password123!')
    
    // Submit
    await page.click('button[type="submit"]')
    
    // Verify redirect
    await expect(page).toHaveURL('/dashboard')
    await expect(page.getByText('Welcome!')).toBeVisible()
  })

  test('user can log in', async ({ page }) => {
    await page.goto('/login')
    
    await page.fill('[name="email"]', 'existing@example.com')
    await page.fill('[name="password"]', 'Password123!')
    
    await Promise.all([
      page.waitForNavigation(),
      page.click('button[type="submit"]'),
    ])
    
    await expect(page).toHaveURL('/dashboard')
  })
})
```

### API Testing
```typescript
// tests/e2e/api.spec.ts
test('API health check', async ({ request }) => {
  const response = await request.get('/api/health')
  expect(response.ok()).toBeTruthy()
  
  const data = await response.json()
  expect(data).toEqual({
    status: 'healthy',
    timestamp: expect.any(String),
  })
})
```

## Bundle Budget

### Configuration
```javascript
// next.config.js
module.exports = {
  experimental: {
    webpackBuildWorker: true,
  },
  webpack: (config, { dev, isServer }) => {
    if (!dev && !isServer) {
      config.performance = {
        hints: 'error',
        maxAssetSize: 250 * 1024, // 250KB
        maxEntrypointSize: 250 * 1024,
      }
    }
    return config
  },
}
```

### Bundle Analysis
```json
// package.json
{
  "scripts": {
    "analyze": "ANALYZE=true next build",
    "analyze:server": "BUNDLE_ANALYZE=server next build",
    "analyze:browser": "BUNDLE_ANALYZE=browser next build"
  }
}
```

### Size Monitoring
```javascript
// scripts/check-bundle-size.js
const { readFileSync } = require('fs')
const { join } = require('path')

const BUILD_MANIFEST = join(process.cwd(), '.next/build-manifest.json')
const manifest = JSON.parse(readFileSync(BUILD_MANIFEST, 'utf8'))

const BUDGETS = {
  'pages/index': 100 * 1024, // 100KB
  'pages/products': 150 * 1024, // 150KB
}

Object.entries(BUDGETS).forEach(([page, budget]) => {
  const assets = manifest.pages[page]
  const totalSize = assets.reduce((sum, asset) => {
    const stats = statSync(join('.next', asset))
    return sum + stats.size
  }, 0)
  
  if (totalSize > budget) {
    console.error(`❌ ${page} exceeds budget: ${totalSize} > ${budget}`)
    process.exit(1)
  }
})
```

## Security Headers

### Middleware Configuration
```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const response = NextResponse.next()
  
  // Security headers
  response.headers.set('X-DNS-Prefetch-Control', 'on')
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-Frame-Options', 'SAMEORIGIN')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')
  
  // Content Security Policy
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://vercel.live",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' blob: data: https:",
    "font-src 'self'",
    "connect-src 'self' https://api.example.com wss://localhost:* ws://localhost:*",
    "media-src 'self'",
    "frame-ancestors 'none'",
  ].join('; ')
  
  response.headers.set('Content-Security-Policy', csp)
  
  return response
}
```

### Rate Limiting
```typescript
// middleware/rateLimit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})

export async function rateLimit(request: NextRequest) {
  const ip = request.ip ?? '127.0.0.1'
  const { success } = await ratelimit.limit(ip)
  
  if (!success) {
    return new Response('Too Many Requests', { status: 429 })
  }
}
```

## Additional Best Practices

### Error Boundaries
```typescript
// app/error.tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
    // Send to error tracking service
    captureException(error)
  }, [error])

  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <h2 className="text-2xl font-bold">Something went wrong!</h2>
      <button
        onClick={reset}
        className="mt-4 rounded bg-blue-500 px-4 py-2 text-white"
      >
        Try again
      </button>
    </div>
  )
}
```

### Loading States
```typescript
// app/loading.tsx
export default function Loading() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="h-32 w-32 animate-spin rounded-full border-b-2 border-gray-900" />
    </div>
  )
}
```

This comprehensive guide should help Claude Code work effectively with Next.js projects!