import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Hena Qena API',
      version: '1.0.0',
      description: 'منصة خدمات المجتمع المحلي في محافظة قنا',
      contact: {
        name: 'Hena Qena Team',
        url: 'https://henaqena.example.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:4000',
        description: 'Development server'
      },
      {
        url: 'https://api.henaqena.example.com',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Session token from login/register'
        },
        adminKey: {
          type: 'apiKey',
          in: 'header',
          name: 'x-admin-key',
          description: 'Admin API key for protected endpoints'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            phone: { type: 'string' },
            email: { type: 'string' },
            phoneVerified: { type: 'boolean' },
            emailVerified: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        Area: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            city: { type: 'string' },
            isActive: { type: 'boolean' }
          }
        },
        Category: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            slug: { type: 'string' },
            isActive: { type: 'boolean' }
          }
        },
        Provider: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            description: { type: 'string' },
            phone: { type: 'string' },
            whatsapp: { type: 'string' },
            address: { type: 'string' },
            areaId: { type: 'string' },
            status: { type: 'string', enum: ['PENDING', 'APPROVED', 'REJECTED'] },
            isVerified: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        Error: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            errors: { type: 'array', items: { type: 'object' } }
          }
        }
      }
    },
    tags: [
      {
        name: 'Health',
        description: 'System health check'
      },
      {
        name: 'Authentication',
        description: 'User registration, login, and verification'
      },
      {
        name: 'Public',
        description: 'Public endpoints for discovering services'
      },
      {
        name: 'Admin',
        description: 'Admin moderation and management endpoints'
      }
    ]
  },
  apis: []
};

export const swaggerSpec = swaggerJsdoc(options);

/**
 * @swagger
 * /health:
 *   get:
 *     tags:
 *       - Health
 *     summary: Health check
 *     description: Check if the API is running
 *     responses:
 *       200:
 *         description: API is healthy
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                 service:
 *                   type: string
 *
 * /api/auth/register:
 *   post:
 *     tags:
 *       - Authentication
 *     summary: Register a new user
 *     description: Create a new user account
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - phone
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *                 minLength: 2
 *                 maxLength: 80
 *               phone:
 *                 type: string
 *                 pattern: '^01[0125][0-9]{8}$'
 *                 example: "01001234567"
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 maxLength: 128
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Invalid input
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       409:
 *         description: User already exists
 *       429:
 *         description: Too many requests
 *
 * /api/auth/login:
 *   post:
 *     tags:
 *       - Authentication
 *     summary: Login user
 *     description: Authenticate user with phone and password
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - password
 *             properties:
 *               phone:
 *                 type: string
 *                 pattern: '^01[0125][0-9]{8}$'
 *               password:
 *                 type: string
 *                 minLength: 1
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         description: Invalid credentials
 *       429:
 *         description: Too many requests
 *
 * /api/areas:
 *   get:
 *     tags:
 *       - Public
 *     summary: Get all areas
 *     description: Retrieve list of geographic areas
 *     responses:
 *       200:
 *         description: List of areas
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Area'
 *
 * /api/categories:
 *   get:
 *     tags:
 *       - Public
 *     summary: Get all categories
 *     description: Retrieve list of service categories
 *     responses:
 *       200:
 *         description: List of categories
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Category'
 *
 * /api/admin/overview:
 *   get:
 *     tags:
 *       - Admin
 *     summary: Get admin overview
 *     security:
 *       - adminKey: []
 *     responses:
 *       200:
 *         description: Admin statistics
 *       403:
 *         description: Unauthorized
 *
 * /api/admin/providers:
 *   get:
 *     tags:
 *       - Admin
 *     summary: Get all providers (admin)
 *     security:
 *       - adminKey: []
 *     responses:
 *       200:
 *         description: List of all providers
 *       403:
 *         description: Unauthorized
 */
