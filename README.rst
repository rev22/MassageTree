Massage Trees: Self-adjusting, self-balancing binary search trees

This archive contains a reference implementation of a data structure with novel performance properties.

The programming language employed for this implementation is Mythryl, a functional, strongly-typed programming language in the ML family.

All the code in the reference implementation and the paper is licensed under the GPLv3+, please read the file COPYING for the terms of the license.

Copyright (c) 2013, 2014, 2015 Michele Bini <michele.bini@gmail.com>

Follows a draft of the research paper.   The paper itself, with the exception of code, is licensed under the GNU Free Documentation License.


Synopsis:

The self-adjusting property of splay trees is combined with a self-balancing
property, thereby improving the worst-case time complexity of basic
operations from linear to logarithmic to the size of the tree. The
resulting persistent data structure can be used or adapted to simulate efficiently and seamlessly
a variety of more specialized data structures.

Keywords: self-balancing trees, self-adjusting 

[TOC]

Introduction:
---

Among the data structures available to programmers, some of them,
like lists, stacks or queues are specialized for sequential, or local-access
operations. Others, like balanced trees, are specialized for random-access
operations.

The goal of this paper is addressing the duality between these data-structures,
by providing algorithms for a generic tree structure reconciling constant
time bounds for sequential and local operations, with logarithmic
time bounds for random-access operations. For brevity in this paper
``focal'' will be used to indicate either sequential or local type
of accesses and combinations of them.
 <table>
 <tr>
 <td>
 <th colspan=2> random insert/replace/delete
 <th> focal insert/replace/delete
 <tr>
 <td>
 <th>amortized <th>worst-case
 <th>amortized
 <tr>
 <td>Red-black tree
 <td>O(log(n)) <td>O(log(n))
 <td>O(log(n)) 
 <tr>
 <td>Splay tree
 <td>O(log(n)) <td>O(n)
 <td>**O(1)**
 <tr>
 <td>Massage tree
 <td>O(log(n)) <td>**O(log(n))**
 <td>O(1) 
 </table>
This paper will first survey cover basic techniques and theories for
splay trees, then describe a rebalancing operation with amortized
constant time complexity that can be employed to lower the worst-case
time bounds of all basic operations.

Finally, a fully constant-time rebalancing operation is embedded into
the splay operation.

Each step will supported by theoretical and experimental data.

For ease of analisys of the time bounds, an eager order of execution
will be assumed.

Basic theories and techniques
-----------------------------


Functional set operations
=========================

$$
\newcommand{\lincell}{\cellcolor{gray2}\text{linear}}
\newcommand{\logcell}{\cellcolor{gray1}\text{logarithmic}}
\newcommand{\concell}{\text{constant}}
\newcommand{\insert}{\mathit{\textbf{insert}}}
\newcommand{\member}{\textbf{member}}
\newcommand{\concat}{\textbf{concat}}
\newcommand{\delete}{\textbf{delete}}
\newcommand{\queuepush}{\mathit{\textbf{push}}}
\newcommand{\queuepop}{\textbf{pop}}
\newcommand{\seqfirst}{\textbf{first}}
\newcommand{\seqlast}{\textbf{last}}
\newcommand{\seqjoin}{\textbf{join}}
\newcommand{\seqsplit}{\textbf{split}}
\newcommand{\height}{\textbf{h}}
\newcommand{\size}{\textbf{s}}
\newcommand{\Tree}{\mathsf{Tree}}
\newcommand{\Measures}{\mathsf{Measures}}
\newcommand{\Height}{\mathsf{Height}}
\newcommand{\node}{\textbf{node}}
\newcommand{\splay}{\textbf{splay}}
\newcommand{\massage}{\textbf{massage}}
\newcommand{\descend}{\textbf{descend}}
\newcommand{\compress}{\textbf{pack}}
\newcommand{\add}{\textbf{add}}
\newcommand{\build}{\textbf{build}}
\newcommand{\ascend}{\textbf{ascend}}
\newcommand{\loopy}{\textbf{loop}}
\newcommand{\true}{\boldsymbol{\top}}
\newcommand{\false}{\boldsymbol{\bot}}
\newcommand{\indent}{\;\;\;\;}
\newcommand{\gentree}{\textbf{G}}
\newcommand{\baltree}{\textbf{B}}
\newcommand{\splayop}{\textbf{Spl}}
\newcommand{\genop}{\textbf{Gen}}
\newcommand{\massageop}{\textbf{Mas}}
\newcommand{\OrderedSet}{\textbf{X}}
\newcommand{\emptytup}{\varnothing}
\newcommand{\balancedness}{\textbf{b}}
\newcommand{\codedescription}[1]{\mathit{#1}}
$$

In the context of this paper, $\OrderedSet$ is a totally ordered set, while $\member,\insert,\delete$ are functions whose type can be described by the set $\left\{ (t_{1},x)\to t_{2}|x\in\OrderedSet\land t_{x}\in\mathbf{T}\right\} $, where $\mathbf{T}$ is the data type of a tree set implementation.

Binary search trees
----
It is straightforward to define simple $\member$ and $\insert$ operations
on a generic binary search tree:

\begin{align}
 & \begin{aligned} & \gentree=\left\{ \emptytup_{\gentree},\left\langle l,x,r\right\rangle _{\gentree}\mid l,r\in\gentree\land x\in\OrderedSet\right\} \end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \member(\emptytup_{\gentree},x) &  & \to\false\\
 & \member(\left\langle l,m,r\right\rangle _{\gentree},x) &  & \to
\end{aligned}
\\
 & \begin{aligned} & \indent x<m &  & \Rightarrow\member(l,x)\\
 & \indent x>m &  & \Rightarrow\member(r,x)\\
 & \indent x=m &  & \Rightarrow\true
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \insert(\emptytup_{\gentree},x) &  & \to\left\langle \emptytup_{\gentree},x,\emptytup_{\gentree}\right\rangle _{\gentree}\\
 & \insert(\left\langle l,m,r\right\rangle _{\gentree},x) &  & \to
\end{aligned}
\\
 & \begin{aligned} & \indent x<m &  & \Rightarrow\left\langle \insert(l,x),m,r\right\rangle _{\gentree}\\
 & \indent x>m &  & \Rightarrow\left\langle l,m,\insert(r,x)\right\rangle _{\gentree}\\
 & \indent x=m &  & \Rightarrow\left\langle l,x,r\right\rangle _{\gentree}
\end{aligned}
\end{align}

A delete operation is necessarily more complex than insert on binary
search trees, since deletions can also occur in a node with branches.
Implementations of this operation for generic binary search trees
are omitted for brevity and not used by other code of this paper.

Evaluating tree balance
----

Basic operations on binary trees have worst-case time bounds proportional
to the height of the tree, defined as the distance between the root
node and the deepest node of the tree.

*Lemma:* A perfectly balanced binary tree of height $h$ has size $2^{h}-1$.

*Proof:*
Let $\size_{\text{t}}(h)$ be the size of a perfect binary tree of
height $h$.
\begin{eqnarray}
\size_{\text{t}}(1) & = & 1\\
\size_{\text{t}}(n) & = & \size_{\text{t}}(n-1)+2^{n-1}\\
\size_{\text{t}}(n) & = & \sum_{x=1}^{n}2^{n-1}=1\frac{1-2^{n}}{1-2}=2^{n}-1
\end{eqnarray}

*Lemma:* The height of a perfectly balanced binary tree of size s is $\height_{\text{t}}(s)=\log_{2}(s+1)$
for $(s+1)\in\left\{ x^{2}\mid x\in\mathbb{N}\right\} $.
\end{lem}
For arbitrary sizes, rounding up the result is necessary:
\begin{equation}
\height_{\text{t}}(s)=\left\lceil \log_{2}(s+1)\right\rceil \in\mathbb{N}
\end{equation}
.

The balancedness $\balancedness(t)$ of a non-empty tree $t$ can
be defined as the ratio between the height for a balanced binary tree
of the same size and the measured height of the tree.
\begin{align}
\balancedness(t) & =\frac{\height_{\text{t}}(\size(t))}{\height(t)}\in\{x\mid x\in\mathbb{R}\land0<x\le1\}
\end{align}


By annotating each node with the size and height of the corresponding
subtree, it is possible to calculate the balancedness of trees in
constant time. A smart constructor (2.18) can be defined to maintain
the size and height annotations of the nodes.
\begin{align}
 & \begin{aligned} & \mathbf{\baltree}=\left\{ \emptytup_{\baltree},\left\langle \left\langle h,s\right\rangle ,l,x,r\right\rangle _{\baltree}\mid h,s\in\mathbb{N}\land l,r\in\mathbf{\baltree}\land x\in\OrderedSet\right\} \end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \size(\emptytup_{\baltree}) &  & \to0\\
 & \size\left\langle \left\langle \_,s\right\rangle ,\_,\_,\_\right\rangle _{\baltree} &  & \to s
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \height(\emptytup_{\baltree}) &  & \to0\\
 & \height\left\langle \left\langle h,\_\right\rangle ,\_,\_,\_\right\rangle _{\baltree} &  & \to h
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \left\langle l,m,r\right\rangle _{\baltree}\to\left\langle \left\langle \height(l)\oplus\height(r)+1,\size(l)+\size(r)+1\right\rangle ,l,m,r\right\rangle _{\baltree}\end{aligned}
\end{align}

In this definition, the operator $\oplus$ returns the maximum of
the two operands.

Functional splay trees
-----

Splay trees do not require any node annotation, thus they can use
the same data structure primitives as other binary search trees. The
characterizing operation on splay trees is the splay operation, having
two crucial properties {[}SELFADJ{]}:

 - bringing to the top the target node
 - reduce the height of the tree along the path to the target node

The novel algorithm presented here subdivides the splay operation
into a descending (2.16) phase, which accumulates lists of trees on
either side of the path to the target node, and an ascending (2.18)
phase, during which the lists of trees are assembled into a pair of
trees of reduced height and placed as subtreres on either side of
the target node.

\begin{align}
 & \begin{aligned} & \splay(\emptytup_{\gentree},x) &  & \to\emptytup_{\gentree}\\
 & \splay(t,x) &  & \to\descend(x,t,\left\langle \left[\right],\left[\right]\right\rangle )
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \descend(x,t\equiv\left\langle l,m,r\right\rangle _{\gentree},f)\to\end{aligned}
\\
 & \begin{aligned} & \indent x<m\Rightarrow\descend^{\prime}(x,l,\add_{r}(m,r,f),t,f)\\
 & \indent x>m\Rightarrow\descend^{\prime}(x,r,\add_{l}(m,l,f),t,f)\\
 & \indent x=m\Rightarrow\ascend(m,l,r,f)
\end{aligned}
\nonumber \\
\nonumber \\
 & \begin{aligned} & \descend^{\prime}(\_,\emptytup_{\gentree},\_,\left\langle l,m,r\right\rangle _{\gentree},f) &  & \to\ascend(m,l,r,f)\\
 & \descend^{\prime}(x,t,f,\_,\_) &  & \to\descend(x,t,f)
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \ascend(m,l,r,\left\langle l_{f,},r_{f}\right\rangle )\to\\
 & \indent\left\langle \build(\node_{l},l,l_{f}),m,\build(\node_{r},r,r_{f})\right\rangle _{\gentree}
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \add_{r}(m,r,\left\langle f_{l},f_{r}\right\rangle )\to\left\langle f_{l},\left[\left\langle m,r\right\rangle ,f_{r}\dots\right]\right\rangle \\
 & \add_{l}(m,l,\left\langle f_{l},f_{r}\right\rangle )\to\left\langle \left[\left\langle m,l\right\rangle ,f_{l}\dots\right],f_{r}\right\rangle 
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \node_{r}(l,m,r)\to\left\langle l,m,r\right\rangle _{\gentree}\\
 & \node_{l}(r,m,l)\to\left\langle l,m,r\right\rangle _{\gentree}
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \build(n,t,\left[\left\langle v_{a},t_{a}\right\rangle ,\left\langle v_{b},t_{b}\right\rangle ,f\dots\right])\to\build(n,n(t,v_{a},n(t_{a},v_{b},t_{b}),f))\\
 & \build(n,t,\left[\left\langle v_{a},t_{a}\right\rangle \right])\to n(t,v_{a},t_{a})\\
 & \build(n,t,\left[\right])\to t
\end{aligned}
\end{align}

This splay variant has been shown experimentally to be more performant
than a top-down functional splaying algorithm, and has the additional
advantages of a concise implementation and simpler analysis.

The splay operation is typically performed before other basic operations
to bring the target node to the top, and to optimize subsequent operations
in the same locality of reference:
\begin{align}
 & \begin{aligned} & \member_{\splayop}(t,x)\to(\splay(t,x),\member_{\genop}(\splay(t,x),x))\\
 & \indent t\leftarrowtail\splay(t,x)\\
 & \indent\left\langle t,\member_{\genop}(t,x)\right\rangle \\
\\
 & \insert_{\splayop}(t,x)\to\insert_{\genop}(\splay(t,x),x)\\
 & \delete_{\splayop}(t,x)\to\delete_{\text{\ensuremath{\genop}}}(\splay(t,x),x)
\end{aligned}
\end{align}

It is equivalently possible to perform the splay operation \textit{after}
the corresponding function for generic binary search tree:
\begin{equation}
\begin{cases}
 & f_{1}(t,x)=\splay(f_{\genop}(t,x),x)\\
 & f_{2}(t,x)=f_{\genop}(\splay(t,x),x)
\end{cases}
\end{equation}


Integrated splay tree operations
----

For optimal performance of implementations of splay trees, it is adviced
to embed the splay operation into the basic binary search tree operation.

\begin{align}
 & \begin{aligned} & \member_{\splayop}(\emptytup_{\gentree},x) &  & \to\left\langle \emptytup_{\gentree},\false\right\rangle \\
 & \member_{\splayop}(t,x) &  & \to\descend(x,t,\left\langle \left[\right],\left[\right]\right\rangle )
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \descend(x,t\equiv\left\langle l,m,r\right\rangle _{\gentree},f)\to\end{aligned}
\\
 & \begin{aligned} & \indent x<m\Rightarrow\descend^{\prime}(x,l,\add_{r}(m,r,f),t,f)\\
 & \indent x>m\Rightarrow\descend^{\prime}(x,r,\add_{l}(m,l,f),t,f)\\
 & \indent x=m\Rightarrow\ascend(\true,m,l,r,f)
\end{aligned}
\nonumber \\
\nonumber \\
 & \begin{aligned} & \descend^{\prime}(\_,\emptytup_{\gentree},\_,\left\langle l,m,r\right\rangle _{\gentree},f) &  & \to\ascend(\false,m,l,r,f)\\
 & \descend^{\prime}(x,t,f,\_,\_) &  & \to\descend(x,t,f)
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \ascend(v,x,l,r,\left\langle l_{f,},r_{f}\right\rangle )\to\\
 & \indent\left\langle \left\langle \build(\node_{l},l,l_{f}),x,\build(\node_{r},r,r_{f})\right\rangle _{\gentree},v\right\rangle 
\end{aligned}
\end{align}

\begin{align}
 & \begin{aligned} & \insert_{\splayop}(\emptytup_{\gentree},x) &  & \to\left\langle \emptytup_{\gentree},x,\emptytup_{\gentree}\right\rangle _{\gentree}\\
 & \insert_{\splayop}(t,x) &  & \to\descend(x,t,\left\langle \left[\right],\left[\right]\right\rangle )
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \descend(x,t\equiv\left\langle l,m,r\right\rangle _{\gentree},f)\to\end{aligned}
\\
 & \begin{aligned} & \indent x<m\Rightarrow\descend^{\prime}(x,l,\add_{r}(m,r,f))\\
 & \indent x>m\Rightarrow\descend^{\prime}(x,r,\add_{l}(m,l,f))\\
 & \indent x=m\Rightarrow\ascend(x,l,r,f)
\end{aligned}
\nonumber \\
\nonumber \\
 & \begin{aligned} & \descend^{\prime}(x,\emptytup_{\gentree},f) &  & \to\ascend(x,\emptytup_{\gentree},\emptytup_{\gentree},f)\\
 & \descend^{\prime}(x,t,f) &  & \to\descend(x,t,f)
\end{aligned}
\end{align}

In the original paper for splay trees {[}selfadj{]}, basic set operations
are constructed by first embedding splay the operation into each access/join/split
operation, then defining insert and delete in terms of split and join.
While conceptually simple, this has the drawback, for the delete operation,
that two distinct splay operations would be performed.

\begin{align}
 & \begin{aligned} & \delete_{\splayop}(\emptytup_{\gentree},x) &  & \to\emptytup\\
 & \delete_{\splayop}(t\equiv\left\langle l,m,r\right\rangle _{\gentree},x) &  & \to\descend(x,t,\left\langle \left[\right],\left[\right]\right\rangle )
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \descend_{\seqjoin}(t,\emptytup_{\gentree},f)\to\ascend^{\prime}(t,f)\\
 & \descend_{\seqjoin}(\emptytup_{\gentree},t,f)\to\ascend^{\prime}(t,f)\\
 & \descend_{\seqjoin}(\left\langle l_{a},m_{a},r_{a}\right\rangle _{\gentree},\left\langle \emptytup_{\gentree},m_{b},r_{b}\right\rangle _{\gentree},f)\to\\
 & \indent\ascend(m_{b},r_{a},r_{b},\add_{l}(m_{a},l_{a},f))\\
 & \descend_{\seqjoin}(\left\langle l_{a},m_{a},\emptytup_{\gentree}\right\rangle _{\gentree},\left\langle l_{b},m_{b},r_{b}\right\rangle _{\gentree},f)\to\\
 & \indent\ascend(m_{a},l_{a},l_{b},\add_{r}(m_{b},r_{b},f))
\end{aligned}
\\
 & \begin{aligned} & \descend_{\seqjoin}(\left\langle l_{a},m_{a},r_{a}\right\rangle _{\gentree},\left\langle l_{b},m_{b},r_{b}\right\rangle _{\gentree},f)\to\\
 & \indent\descend_{\seqjoin}(r_{a},l_{b},\add_{l}(m_{a},l_{a},\add_{r}(m_{b},r_{b},f)))
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \descend(x,t\equiv\left\langle l,m,r\right\rangle _{\gentree},f)\to\end{aligned}
\\
 & \begin{aligned} & \indent x<m\Rightarrow\descend^{\prime}(x,l,\add_{r}(m,r,f),t,f)\\
 & \indent x>m\Rightarrow\descend^{\prime}(x,r,\add_{l}(m,l,f),t,f)\\
 & \indent x=m\Rightarrow\descend_{\seqjoin}(l,r,t,f)
\end{aligned}
\nonumber \\
\nonumber \\
 & \begin{aligned} & \descend^{\prime}(\_,\emptytup_{\gentree},\_,\left\langle l,m,r\right\rangle _{\gentree},f) &  & \to\ascend(m,l,r,f)\\
 & \descend^{\prime}(x,t,f,\_,\_) &  & \to\descend(x,t,f)
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \ascend^{\prime}(t,\left\langle \left[\right],f\right\rangle ) &  & \to\build(\node_{r},t,f)\\
 & \ascend^{\prime}(t,\left\langle f,\left[\right]\right\rangle ) &  & \to\build(\node_{l},t,f)
\end{aligned}
\\
 & \begin{aligned} & \ascend^{\prime}(t,\left\langle \left[\left\langle m_{l},l\right\rangle ,f_{l}\ldots\right],f_{r}\right\rangle )\to\ascend(m_{l},l,t,\left\langle f_{l},f_{r}\right\rangle )\end{aligned}
\end{align}

Analysis of the splay operation
----

*Lemma:* The maximum height increase of a tree after a suitably designed splay
operation is constant.

$$
\forall x\in\gentree\colon(\height(\splay(x))-\height(x))\oplus0=O(1)
$$

*Proof:* Splaying the empty tree results in an empty tree, with no height change.

For non-empty trees, we analize the behaviour of the previously
provided splaying algorithm. In this implementation the splaying operation
can be subdivided into a descending phase, and an assembling phase.

The descending phase starts with the tree to splay and two lists of
trees initially empty, each representing one half of a finger structure.
During each step of the descending phase, if the node to bring to
the top is not the one being visited, the subtree more distant to
the target node is added to the the corresponding list in the finger
structure. When the node to bring to the top is visited, a new tree
is assembled, by first assembling each of the lists of trees in each
side into a tree, and then adding the resulting trees as subtrees
of the top node. Therefore, the resulting tree has an height of one
plus the maximum height of the subtrees assembled from the lists in
the finger structure. Thus proving that the height of the assembled
subtree can at most increase by a constant compared to the original
tree, is equivalent to proving this lemma.

Let $m\in\mathbb{N}$ be the height of the tree before the splay operation,
and $n\in\mathbb{N}$ the number of descend steps during the splay
operation. The maximum possible heights of subtrees added to any of
the lists during descend steps can then be described by the sequence
$\left\langle m-1,m-2,\ldots,m-n\right\rangle $, of which the heights
of subtrees added to one of the two lists are a subsequence, with
the form $\left\langle m-n_{1},m-n_{2},\ldots,m-n_{s}\right\rangle $,
where $n_{x}+1\le n{}_{x+1}$ and $s$ is the size of the subsequence.
It may be noted that $n_{x}\ge x$

During the assembling phase, the subtrees are assembled back in reverse
order, starting from the last node, also the one with the minimum
of the maximum possible heights of the subtrees.

According to the build algorithm defined in (2.21) the maximum height
$\height_{m}$ of a tree assembled from such a subsequence is defined
recursively by:

\begin{eqnarray*}
 &  & \height_{m}(a,b,c,d\ldots)=\height_{m}(a\boxplus(b\boxplus c),d...)\\
 &  & \height_{m}(a,b)=a\boxplus b\\
 &  & \height_{m}(a)=a
\end{eqnarray*}
with $a\boxplus b=(a\oplus b)+1$ and $a\oplus b=\max(a,b)$.

It is possible to distribute additions of positive values, over the
maximum operator:

$(a\oplus b)+n=(a+n)\oplus(b+n)$ for $n\in\mathbb{N}$

By recursively applying the $n\in\mathbb{N}$ function and distributing
additions, if s is odd, one obtains:

$$
\height_{m}(x_{s},\ldots,x_{2},x_{1})=(x_{s}+\frac{s-1}{2})\oplus\ldots\oplus(x_{4}+3)\oplus(x_{3}+3)\oplus(x_{2}+2)\oplus(x_{1}+2)
$$


Substituting $x_{y}\to m-n_{y}$
\begin{eqnarray*}
\text{} &  & \height_{m}(x_{s},\ldots,x_{2},x_{1})=\\
 &  & =(m-n_{s}+\frac{s-1}{2}\oplus\ldots\oplus(m-n_{4}+3)\oplus(m-n_{3}+3)\oplus(m-n_{2}+2)\oplus(m-n_{1}+2)
\end{eqnarray*}


Given that $n_{x}\ge x$, the maximum possible of these terms is the
last one $(m-n_{1}+2)$. By assuming the minimum value for $n_{1}$,
one obtains that the maximum possible height of the assembled subtree
is $m+1$.

If s is even:
\begin{eqnarray*}
\text{} &  & \height_{m}(x_{s},\ldots,x_{2},x_{1})=(x_{s}+\frac{s}{2})\oplus\ldots\oplus(x_{3}+3)\oplus(x_{2}+3)\oplus(x_{1}+1)
\end{eqnarray*}


In this case the term with the maximum possible value is $(x_{2}+3)$.
By applying the same steps as above, one similarly obtains that the
maximum possible height for the assembled subtree is $m+1$.

The maximum possible height increase of a tree after the splay operation
defined in (2.19) is 2.

*Lemma:* It is possible to design basic operations on splay trees whose maximum
height increase is constant.
Basic operations on splay trees considered in this lemma are lookup,
insert and delete.

*Proof:*
The maximum height increase after a suitably designed splay operation
is constant.

The height increase after a basic binary tree lookup is zero.

The maximum height increase after a basic binary tree insert (2.4)
is one, in the case a leaf is added to a node of maximum depth.

Thus the maximum height increase after performing a splay operation
and a basic binary tree operation, in any order, is constant.


A monolithic rebalancing function
----

The $\massage$ function described here requires that tree nodes are
annotated with balance information. When the balancedness of the tree
falls below a defined threshold, $\balancedness_{\massage}$, the
massage function descends the tree along the deepest path and reassembles
it to reduces its height by a constant factor. This height reduction
is analogous to the $\splay$ operation and is the main rebalancing
operation of massage trees.

The full massage operation is $O(\log n)$, but when $\balancedness_{\massage}$
is sufficiently small it occurs every $(rk)^{-1}\log n$ operations,
where $n$ is the size of the tree, $r$ is the height reduction constant
and $k$ is the maximum height increase after each operation. The
amortized time complexity of the massage operation is then $O(rk\log n/\log n)=O(1)$.
\begin{align}
 & \begin{aligned} & \massage(\emptytup_{\baltree})\to\emptytup_{\baltree}\\
 & \massage(t)\to\\
 & \indent\balancedness(t)<\balancedness_{\massage}\Rightarrow\massage_{a}(t)\\
 & \indent\balancedness(t)\ge\balancedness_{\massage}\Rightarrow t
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \massage_{a}(\left\langle l,m,r\right\rangle _{\baltree})\to\end{aligned}
c\\
 & \begin{aligned} & \indent\height(l)<\height(r)\Rightarrow\node(l,m,\massage_{b}(r))\\
 & \indent\height(l)\ge\height(r)\Rightarrow\node(\massage_{b}(l),m,r)
\end{aligned}
\\
\\
 & \begin{aligned} & \massage_{b}(t\equiv\left\langle l,m,r\right\rangle _{\baltree})\to\end{aligned}
\\
 & \begin{aligned} & \indent\height(l)<\height(r)\Rightarrow\massage_{r}(t, & \left\langle l_{l},m_{r},r_{r}\right\rangle _{\baltree} & \mapsto\left\langle \left\langle l,m,l_{r}\right\rangle _{\baltree},m_{r},r_{r}\right\rangle _{\baltree})\\
 & \indent\height(l)\ge\height(r)\Rightarrow\massage_{l}(t, & \left\langle l_{l},m_{l},r_{l}\right\rangle _{\baltree} & \mapsto\left\langle l_{l},m_{l},\left\langle r_{l},m,r\right\rangle _{\baltree}\right\rangle _{\baltree})
\end{aligned}
\\
\nonumber \\
 & \begin{aligned} & \massage_{l}(t\equiv\left\langle \emptytup_{\baltree},m,r\right\rangle _{\baltree},x,f)\to t\\
 & \massage_{l}(\left\langle l,m,r\right\rangle _{\baltree},x,f)\to f(\massage_{a}(l));
\end{aligned}
\\
\\
 & \begin{aligned} & \massage_{r}(t\equiv\left\langle l,m,\emptytup_{\baltree}\right\rangle _{\baltree},x,f)\to t\\
 & \massage_{r}(\left\langle l,m,r\right\rangle _{\baltree},x,f)\to f(\massage_{a}(r));
\end{aligned}
\end{align}


Operations on massage trees
----

As with $\splay$, $\massage$ is combined with each of the defined
operations on splay trees:
\begin{equation}
\begin{aligned} & \member_{\massageop}(t,x)\to\\
 & \indent\left\langle t,r\right\rangle \leftarrowtail\member_{\splayop}(t,x)\\
 & \indent\left\langle \massage(t),r\right\rangle \\
\\
 & \insert_{\massageop}(t,x)\to\massage(\insert_{\splayop}(t,x))\\
 & \delete_{\massageop}(t,x)\to\massage(\delete_{\text{\ensuremath{\splayop}}}(t,x))
\end{aligned}
\end{equation}


The massage operation may equivalently be performed \textit{after}
or \textit{before} the corresponding function for splay trees:
\begin{equation}
\begin{cases}
 & f_{1}(t,x)=\massage(f_{\splayop}(t,x))\\
 & f_{2}(t,x)=f_{\splayop}(\massage(t),x)
\end{cases}
\end{equation}

### Operations on massage trees

The freedom in the order execution of the splay, massage operations,
allows us to embed the rebalancing operation into the splay operation.


Experimental results
----

Applications
----

### Queues

Queue operations can be defined efficiently on massage trees:

\begin{align}
\begin{aligned} & f\in\left\{ \queuepush,\queuepop\right\} \\
 & \splay_{\seqfirst}(t)=\splay(t,\seqfirst(t))\\
 & f_{s}(t,x)=\massage(f_{s,\genop}(\splay_{\seqfirst}(t),x))
\end{aligned}
\end{align}

### Deques

Similarly, deque operations can be defined on massage trees:

\begin{align}
\begin{aligned} & f\in\left\{ \queuepush,\queuepop\right\} \\
 & s\in\left\{ \seqlast,\seqfirst\right\} \\
 & \splay_{s}=(t)\mapsto\splay(t,s(t))\\
 & \splay_{\seqfirst,\seqlast}=\splay_{\seqfirst}\cdot\splay_{\seqlast}\\
 & f_{s}(t,x)\to\massage(f_{s,\genop}(\splay_{\seqfirst}(t),x))
\end{aligned}
\end{align}


The $\splay_{\seqfirst,\seqlast}$ operation splays both the first
and the last node of the tree. This is necessary to make subsequent
accesses to any of the ends of the deque constant-time.


### Dynamic arrays

Massage trees can be used to implement dynamic arrays efficently.

The split operation is implemented as a variant of the splay operation.


### Linked-list

Massage trees support linked-list operations.


### Ropes

Massage trees make it possible to implement a functional alternative to gap buffers. 


Conclusions
----

Massage Trees
 - Extend the applications of self-adjusting trees to areas initially
covered only by balanced trees
 - Extend the applications of balanced trees to areas so far only covered
by ad-hoc structures, like queues, lists or stacks.

Data-structure implemented by massage trees can adapts interactively to different usage
patterns.

Appendix
----


### Terminology
- *Binary search tree* - an ordered binary tree, without duplicate nodes
