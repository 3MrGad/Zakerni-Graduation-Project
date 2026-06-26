<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TodoCategory extends Model
{
    protected $table = 'todo_categories';
    protected $primaryKey = 'category_id';
    public $timestamps = true;

    protected $fillable = ['patient_id', 'name', 'color', 'icon'];

    public function todos()
    {
        return $this->hasMany(Todo::class, 'category_id', 'category_id');
    }
}