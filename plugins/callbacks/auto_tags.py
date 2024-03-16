from __future__ import print_function

from itertools import chain
from typing import List, Union

from ansible.playbook import Play, Playbook
from ansible.playbook.block import Block
from ansible.playbook.task import Task
from ansible.plugins.callback import CallbackBase


class CallbackModule(CallbackBase):
    def v2_playbook_on_start(self, playbook: Playbook):
        """
        Dynamically add a tag of the same name to each role.
        Note: Plays, roles, task_blocks and tasks can have tags.
        """

        plays: List[Play] = playbook.get_plays()

        tasks: List[Union[Task, Block]] = list(
            chain(*[task for play in plays for task in play.get_tasks()])
        )

        def tag_task_recursive(tasks: List[Union[Task, Block]]):
            for task in tasks:
                if isinstance(task, Block):
                    task.tags += [task._parent.name]
                    tag_task_recursive(task.block)
                else:
                    task.tags += [task.name]

        tag_task_recursive(tasks)
