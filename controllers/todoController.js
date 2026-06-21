const { Todo } = require('../models');

exports.createTodo = async (req, res, next) => {
  try {
    const { title, completed } = req.body;
    const user_id = req.user.id;

    const todo = await Todo.create({
      title,
      completed: completed || false,
      user_id
    });

    res.status(201).json(todo);
  } catch (err) {
    next(err);
  }
};

exports.getTodos = async (req, res, next) => {
  try {
    const user_id = req.user.id;
    const todos = await Todo.findAll({ where: { user_id } });
    res.json(todos);
  } catch (err) {
    next(err);
  }
};

exports.updateTodo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, completed } = req.body;
    const user_id = req.user.id;

    const todo = await Todo.findOne({ where: { id, user_id } });

    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' });
    }

    if (title !== undefined) todo.title = title;
    if (completed !== undefined) todo.completed = completed;

    await todo.save();

    res.json(todo);
  } catch (err) {
    next(err);
  }
};

exports.deleteTodo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    const todo = await Todo.findOne({ where: { id, user_id } });

    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' });
    }

    await todo.destroy();

    res.json({ message: 'Todo deleted successfully' });
  } catch (err) {
    next(err);
  }
};
