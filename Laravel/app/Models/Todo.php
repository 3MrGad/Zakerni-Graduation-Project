<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Todo extends Model
{
    protected $table = 'todos';
    protected $primaryKey = 'todo_id';
    public $timestamps = true;

    protected $fillable = [
        'patient_id', 'category_id', 'title', 'description',
        'priority', 'due_date', 'is_completed', 'completed_at', 'created_by',
    ];

    protected $casts = [
        'is_completed' => 'boolean',
        'due_date'     => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function category()
    {
        return $this->belongsTo(TodoCategory::class, 'category_id', 'category_id');
    }
}