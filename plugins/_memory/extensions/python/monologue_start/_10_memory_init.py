import asyncio
from helpers.extension import Extension
from agent import LoopData

# Direct import - this extension lives inside the memory plugin
from plugins._memory.helpers import memory

_EMBED_RETRY_DELAYS = [10, 15, 20, 30, 45]


class MemoryInit(Extension):

    async def execute(self, loop_data: LoopData = LoopData(), **kwargs):
        if not self.agent:
            return

        last_exc = None
        for i, delay in enumerate([0] + _EMBED_RETRY_DELAYS):
            if delay:
                await asyncio.sleep(delay)
            try:
                await memory.Memory.get(self.agent)
                return
            except Exception as e:
                msg = str(e)
                if "400" in msg or "connection" in msg.lower():
                    last_exc = e
                else:
                    raise
        raise last_exc  # type: ignore
