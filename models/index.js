const sequelize = require('../config/database');
const User = require('./User');
const Todo = require('./Todo');

// Define relationships
User.hasMany(Todo, {
  foreignKey: 'user_id',
  as: 'todos',
});

Todo.belongsTo(User, {
  foreignKey: 'user_id',
  as: 'user',
});

module.exports = {
  sequelize,
  User,
  Todo,
};
