const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const todoController = require('../controllers/todoController');
const validate = require('../middleware/validate');
const auth = require('../middleware/auth');

router.use(auth);

router.post(
  '/',
  [
    body('title').notEmpty().withMessage('Title is required'),
  ],
  validate,
  todoController.createTodo
);

router.get('/', todoController.getTodos);

router.put('/:id', todoController.updateTodo);

router.delete('/:id', todoController.deleteTodo);

module.exports = router;
