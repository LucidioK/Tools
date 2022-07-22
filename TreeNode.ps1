<#
E:\dsv\_LK\VSRM_Tools\PowerShellTools\TreeNode.ps1
$r = [TreeNode]::new(1)
$r.Insert(2)
$r.Insert(3)
$r.Insert(4)
$r.InsertUnder(@(1,4),5)
$r.InsertUnder(@(1,4),6)
$r.InsertUnder(@(1,4,5),7)
$r.InsertUnder(@(1,4,5),8)
$r.InsertUnder(@(1,4,5),9)
$r.Get(@(1,4))
(($r.Get(@(1,4))).Children).val
$r.Scan(4)
$r.Scan(8)
$r.ToList()
#>

class TreeNode {
    [object]$val
    [TreeNode]$parent
    [TreeNode[]]$children
    [Hashtable]$index

    TreeNode() {
        $this.val = $null;
        $this.children = @();
    }

    TreeNode([object]$value) {
        $this.val = $value;
        $this.children = @();
    }


    TreeNode([object]$value, [TreeNode]$parent) {
        $this.val = $value;
        $this.parent = $parent;
        $this.children = @();
    }

    [void] CreateIndex()
    {
        $this.index = @{};
        $this.CreateIndexInternal($this);
    }

    [void] Reparent([TreeNode]$newParent)
    {
        $newParent.parent = $this.parent;
        $this.parent = $newParent;
    }

    [TreeNode] Insert([object]$value)
    {
        $n = [TreeNode]::new($value, $this);
        $this.children += $n;
        $this.AddToRootIndex($n);
        return $n;        
    }

    [TreeNode] InsertUnder([object[]]$pathList, [object]$value)
    {
        $n = $this.Get($pathList);
        return $n.Insert($value);
    }

    [TreeNode] Scan([object]$value)
    {
        if ($this.val -eq $value)
        {
            return $this;
        }
        foreach ($node in $this.children)
        {
            $n = $node.Scan($value);
            if ($n -ne $null)
            {
                return $n;
            }
        }
        return $null;
    }

    [TreeNode] SeekThroughIndex([object]$value)
    {
        if ($this.index -eq $null)
        {
            $this.CreateIndex();
        }
        if ($this.val -eq $value) 
        {
            return $this;
        }
        if ($this.index.ContainsKey($value))
        {
            return $this.index[$value];
        }
        else
        {
            return $null;
        }
    }

    [TreeNode] Get([object[]]$pathList)
    {
        $n = $this;
        for ($i = 1; $i -lt $pathList.Count; $i++)
        {
            if ($n -eq $null -or $pathList[$i - 1] -ne $n.val)
            {
                throw "Invalid Path List.";
            }
            $found = $false;
            foreach ($child in $n.children)
            {
                if ($child.val -eq $pathList[$i])
                {
                    $found = $true;
                    $n = $child;
                    break;
                }
            }
            if (!$found)
            {
                $n = $null;
            }
        }

        return $n;
    }

    [object[]] ToList()
    {
        $l = @();
        return $this.ToListInternal($l);
    }

    [string] ToString()
    {
        $l = $this.ToList();
        $s = "";
        $i = "";
        foreach ($o in $l)
        {
            if ($o -eq "<<<<POP>>>>")
            {
                $i = $i.Substring(0, $i.Length - 1);
            }
            else
            {
                $s += "$i$o`n";
                $i += " ";
            }
        }

        return $s;
    }

    
    [object[]] ToListInternal([object[]]$l)
    {
        $l += $this.val;
        $this.children | foreach { $l = $_.ToListInternal($l) }
        $l += "<<<<POP>>>>";
        return $l;
    }

    [void] CreateIndexInternal([TreeNode]$root)
    {
        $root.index.Add($this.val, $this);
        foreach ($childNode in $this.children)
        {
            $childNode.CreateIndexInternal($root);
        }
    }

    [void] AddToRootIndex([TreeNode]$node)
    {
        for ($parentNode = $node; $parentNode.parent -ne $null; $parentNode = $parentNode.parent){}
        if ($parentNode.index -eq $null)
        {
            $parentNode.index = @{};
        }
        $parentNode.index[$node.val] = $node;
    }
}
