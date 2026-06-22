const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const todoController = require('../controllers/todoController');
const validate = require('../middleware/validate');
const auth = require('../middleware/auth');

router.use(auth);

/**
 * @swagger
 * components:
 *   schemas:
 *     Todo:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           description: The auto-generated id of the todo
 *         title:
 *           type: string
 *           description: The title of your todo
 *         completed:
 *           type: boolean
 *           description: Whether you have done the task
 *         user_id:
 *           type: integer
 *           description: The user who owns the todo
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       example:
 *         id: 1
 *         title: Buy groceries
 *         completed: false
 *         user_id: 1
 *         createdAt: 2026-06-21T00:00:00.000Z
 *         updatedAt: 2026-06-21T00:00:00.000Z
 */

/**
 * @swagger
 * /todos:
 *   post:
 *     summary: Create a new todo
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *                 example: Buy groceries
 *               completed:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       201:
 *         description: The created todo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Todo'
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.post(
  '/',
  [
    body('title').notEmpty().withMessage('Title is required'),
  ],
  validate,
  todoController.createTodo
);

/**
 * @swagger
 * /todos:
 *   get:
 *     summary: Get all todos for the logged-in user
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: A list of todos
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Todo'
 *       401:
 *         description: Unauthorized
 */
router.get('/', todoController.getTodos);

/**
 * @swagger
 * /todos/{id}:
 *   put:
 *     summary: Update a todo by id
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: The todo id
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               completed:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: The updated todo
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Todo'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Todo not found
 */
router.put('/:id', todoController.updateTodo);

/**
 * @swagger
 * /todos/{id}:
 *   delete:
 *     summary: Delete a todo by id
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: The todo id
 *     responses:
 *       200:
 *         description: Todo deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Todo not found
 */
router.delete('/:id', todoController.deleteTodo);

module.exports = router;