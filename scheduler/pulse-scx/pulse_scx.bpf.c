// SPDX-License-Identifier: GPL-2.0
/*
 * pulse_scx - experimental PulseOS sched_ext scheduler core.
 *
 * This intentionally begins with conservative upstream-like placement. The
 * next step is a userspace control plane that marks gaming TGIDs in a BPF map,
 * allowing measured latency-sensitive policy without guessing from process
 * names inside the scheduler.
 */

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <scx/common.bpf.h>

char _license[] SEC("license") = "GPL";

s32 BPF_STRUCT_OPS(pulse_select_cpu, struct task_struct *p,
                   s32 prev_cpu, u64 wake_flags)
{
    bool direct = false;
    s32 cpu = scx_bpf_select_cpu_dfl(p, prev_cpu, wake_flags, &direct);

    if (direct)
        scx_bpf_dsq_insert(p, SCX_DSQ_LOCAL, SCX_SLICE_DFL, 0);

    return cpu;
}

void BPF_STRUCT_OPS(pulse_enqueue, struct task_struct *p, u64 enq_flags)
{
    /*
     * Keep the first implementation intentionally fair. Gaming-specific
     * deadlines/slices will only be introduced with benchmark coverage and a
     * userspace-marked task map so Steam UI/background tasks are not boosted.
     */
    scx_bpf_dsq_insert(p, SCX_DSQ_GLOBAL, SCX_SLICE_DFL, enq_flags);
}

s32 BPF_STRUCT_OPS(pulse_init)
{
    scx_bpf_switch_all();
    return 0;
}

SEC(".struct_ops")
struct sched_ext_ops pulse_ops = {
    .select_cpu = (void *)pulse_select_cpu,
    .enqueue = (void *)pulse_enqueue,
    .init = (void *)pulse_init,
    .name = "pulse_scx",
};
